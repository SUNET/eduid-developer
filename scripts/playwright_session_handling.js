// eduID dev-stack e2e suite for the reworked session handling.
//
// What it covers (all against a running dev stack, https://*.eduid.docker):
//
//   A. Session lifecycle seen from a browser
//      - first contact creates the Redis backed session: cookie flags, TTL, encryption at rest
//      - login writes the authentication state into that same session
//      - the one session is shared by every webapp behind dashboard/idp haproxy
//      - TTL is renewed by requests that change nothing (the renew_ttl path)
//      - expired / tampered / stale cookies degrade to a clean 401 instead of a 500
//      - the CSRF token is session state, not client state
//      - logout in one tab logs the other tab out (no stale authenticated session)
//      - after a logout the IdP asks for a password again (SSO session gone)
//
//   B. Concurrency: what happens when a *sibling* writer touches the same Redis key while one
//      request is in flight - the point of the SessionOutOfSync work in
//      webapp/common/session/{redis_session,eduid_session}.py. A lost write must be detected, and
//      it may only be swallowed when everything lost is known to be harmless
//      (EduIDBaseAppConfig.session_safe_to_lose_paths / session_fatal_other_writer_paths). A
//      logout/reset by the other writer must always be fatal, which is what the session generation
//      marker (_generation_) is for.
//
//      Reproducing that race in a browser is normally timing-luck. It is made deterministic here by
//      freezing MongoDB (docker pause) *after* the request has loaded its session from Redis
//      (every @require_user view reads Mongo), performing the sibling write in Redis while the
//      request is stuck, and thawing MongoDB again. The request then commits against a session it
//      never saw - which is what a second browser tab or a second webapp does in production.
//
//      The "sibling writer" is scripts/session_probe.py, run inside a webapp container so it uses
//      the real session code and can read/write the encrypted session data. Verdicts are checked
//      both as seen by the client (HTTP status) and as logged by the app (which classification the
//      conflict got).
//
//      One test is marked XFAIL (known gap, not counted as a failure): two webapps that both
//      generate the csrf token for the same brand new session. When the two writes actually
//      overlap the loser is failed with 500, because a lost "_csrft_" write is not on the
//      safe-to-lose list. It reports XPASS whenever the writes happen not to collide, or once the
//      gap is fixed - check the session log to tell the two apart.
//
// Prereqs: dev stack up (`make start`), docker CLI usable from this shell, the `playwright` npm
// package with Chromium. ignoreHTTPSErrors is on, so pki/rootCA.crt need not be imported.
//
// Run:
//   scripts/run_playwright playwright_session_handling.js
//   HEADED=1 scripts/run_playwright playwright_session_handling.js     # watch it
//   scripts/run_playwright playwright_session_handling.js --only concurrency
//   scripts/run_playwright playwright_session_handling.js --list
//
// Options:
//   --only <substring>    only run tests whose name contains <substring>
//   --skip <substring>    skip those tests
//   --list                list test names and exit
//   --email <addr> --password <pw>   reuse an existing account instead of signing up
//   --account-file <path>            read/write {email, password} here, to re-run the suite
//                                    against the same account without signing up again
//   --no-chaos            skip the tests that need `docker pause` on the mongodb container
//   --keep-open <ms>      keep the browser open at the end, for debugging
//
// The suite only touches the dev stack: it creates accounts, writes sessions, and pauses/unpauses
// the mongodb container for a few seconds per concurrency test (always unfrozen again on the way
// out, also when a test fails).
//
// Signup uses the dev/staging magic-cookie backdoor (config/config.yaml webapp.common.magic_cookie)
// for the captcha and the e-mail verification code, like the other playwright_* scripts here.

const { chromium } = require("playwright");
const { execFileSync } = require("child_process");
const fs = require("fs");

// --------------------------------------------------------------------------------------------
// configuration
// --------------------------------------------------------------------------------------------

const URLS = {
  html: "https://html.eduid.docker",
  dashboard: "https://dashboard.eduid.docker",
  signup: "https://signup.eduid.docker",
  idp: "https://idp.eduid.docker",
};

const EP = {
  jsconfig: `${URLS.dashboard}/services/jsconfig/config`,
  allUserData: `${URLS.dashboard}/services/personal-data/all-user-data`,
  userLanguage: `${URLS.dashboard}/services/personal-data/user/language`,
  credentials: `${URLS.dashboard}/services/security/credentials`,
  authnStatus: `${URLS.dashboard}/services/security/authn-status`,
  suggestedPassword: `${URLS.dashboard}/services/security/change-password/suggested-password`,
  idpLogout: `${URLS.idp}/services/idp/logout`,
};

// webapp container used to run scripts/session_probe.py (it needs the eduid venv + Redis access)
const PROBE_CONTAINER = process.env.PROBE_CONTAINER || "eduid-idp-1";
const MONGO_CONTAINER = process.env.MONGO_CONTAINER || "eduid-mongodb-1";
const MAGIC_COOKIE_NAME = process.env.MAGIC_COOKIE_NAME || "autotests";
const MAGIC_COOKIE_VALUE =
  process.env.MAGIC_COOKIE_VALUE || "w9eB5yt2TwEoDsTNgzmtINq03R24DPQD8ubmRVfXPOST3gRi";
const CAPTCHA_BACKDOOR_CODE = "123456"; // MagicCookieMixin.captcha_backdoor_code default
const SESSION_COOKIE = "sessid"; // webapp.common.flask.session_cookie_name
const SESSION_TTL = 28800; // 2 * flask.permanent_session_lifetime (14400), see SessionFactory
const SCREENSHOT_DIR = process.env.SCREENSHOT_DIR || "/tmp";
// the webapps' CSRF check wants this header on state changing requests
const XHR = { "X-Requested-With": "XMLHttpRequest" };

const argv = process.argv.slice(2);

function flagValue(flag) {
  const i = argv.indexOf(flag);
  return i >= 0 && i + 1 < argv.length ? argv[i + 1] : undefined;
}

const OPTS = {
  only: flagValue("--only"),
  skip: flagValue("--skip"),
  listOnly: argv.includes("--list"),
  email: flagValue("--email"),
  password: flagValue("--password"),
  chaos: !argv.includes("--no-chaos") && process.env.NO_CHAOS !== "1",
  accountFile: flagValue("--account-file") || process.env.ACCOUNT_FILE || "",
  keepOpen: Number(flagValue("--keep-open") || 0),
};

// --------------------------------------------------------------------------------------------
// docker / redis / application log helpers
// --------------------------------------------------------------------------------------------

function docker(cmdArgs, options = {}) {
  return execFileSync("docker", cmdArgs, { encoding: "utf8", maxBuffer: 64 * 1024 * 1024, ...options });
}

/** Run scripts/session_probe.py inside PROBE_CONTAINER and return the JSON it printed. */
function probe(...probeArgs) {
  const out = docker(
    [
      "exec", "-i", "-e", "PYTHONPATH=/opt/eduid/sources", PROBE_CONTAINER,
      "/opt/eduid/webapp/bin/python3", "/tmp/session_probe.py",
      ...probeArgs.map(String),
    ],
    { input: "" },
  );
  const line = out.trim().split("\n").filter(Boolean).pop();
  let parsed;
  try {
    parsed = JSON.parse(line);
  } catch (e) {
    throw new Error(`probe ${probeArgs[0]} returned unparsable output: ${out}`);
  }
  if (parsed.error) throw new Error(`probe ${probeArgs.join(" ")} failed: ${parsed.error}`);
  return parsed;
}

function readSession(cookieValue) {
  return probe("read", cookieValue);
}

/**
 * Everything the apps logged about one session: every session-related log line carries the short
 * session id (the first 9 characters of the cookie), and the conflict decision lines are logged
 * immediately after it. Grep rather than slicing by time or offset: these files are DEBUG chatty,
 * size-cycled, and rewritten whenever the dev apps reload.
 */
function sessionLog(app, cookie, lines = 14) {
  try {
    return docker(["exec", `eduid-${app}-1`, "grep", "-a", "-A", String(lines), cookie.slice(0, 9),
      `/var/log/eduid/${app}-error.log`]);
  } catch (e) {
    return ""; // grep exits 1 when nothing matched
  }
}

/** Drop the DEBUG noise from a log excerpt. */
function quiet(log) {
  return log.split("\n").filter((line) => !/\bDEBUG\b/.test(line)).join("\n");
}

function containerPaused(name) {
  try {
    return docker(["inspect", "-f", "{{.State.Status}}", name]).trim() === "paused";
  } catch (e) {
    return false;
  }
}

/**
 * Freeze MongoDB: a request that has already loaded its Redis session then stalls before it can
 * commit, which is the window the sibling writer needs. Unfreezing lets the request commit
 * against data it never saw.
 */
async function withFrozenMongo(body) {
  docker(["pause", MONGO_CONTAINER]);
  // the freezer takes effect asynchronously
  for (let i = 0; i < 20 && !containerPaused(MONGO_CONTAINER); i++) await sleep(100);
  if (!containerPaused(MONGO_CONTAINER)) {
    docker(["unpause", MONGO_CONTAINER]);
    throw new Error(`could not pause ${MONGO_CONTAINER} (needed to make the race deterministic)`);
  }
  try {
    return await body();
  } finally {
    docker(["unpause", MONGO_CONTAINER]);
    await new Promise((r) => setTimeout(r, 400)); // let the thawed request finish
  }
}

async function cookieValue(context) {
  const cookies = await context.cookies(URLS.dashboard);
  const sess = cookies.find((c) => c.name === SESSION_COOKIE);
  return sess ? sess.value : null;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * locator.isVisible({timeout}) does not wait (the option is ignored), so wait explicitly.
 */
function visibleWithin(locator, ms) {
  return locator.first().waitFor({ state: "visible", timeout: ms }).then(() => true, () => false);
}

/** The webapps unmarshal request bodies with get_json(), so send real JSON. */
function postJson(context, url, body) {
  return context.request.post(url, {
    headers: { ...XHR, "Content-Type": "application/json" },
    data: JSON.stringify(body),
  });
}

// --------------------------------------------------------------------------------------------
// a very small test harness
// --------------------------------------------------------------------------------------------

const results = [];
let failures = 0;

/** Thrown by a test that cannot run here (as opposed to one that fails). */
class Skip extends Error {}

async function test(name, fn, options = {}) {
  results.push({ name });
  if (OPTS.only && !name.includes(OPTS.only)) return record(name, "skipped");
  if (OPTS.skip && name.includes(OPTS.skip)) return record(name, "skipped");
  if (OPTS.listOnly) return record(name, "listed");
  process.stdout.write(`\n${name}\n`);
  const start = Date.now();
  try {
    await fn();
    if (options.xfail) {
      note(`this was expected to fail, but it passed - the known gap looks fixed: ${options.xfail}`);
      return record(name, "XPASS", Date.now() - start);
    }
    record(name, "ok", Date.now() - start);
  } catch (err) {
    if (err instanceof Skip) return record(name, "skipped");
    if (options.xfail) {
      console.log(`      known gap: ${options.xfail}`);
      return record(name, "XFAIL", Date.now() - start, err);
    }
    failures++;
    record(name, "FAIL", Date.now() - start, err);
  }
}

function record(name, status, ms = 0, err) {
  const entry = results.find((r) => r.name === name);
  entry.status = status;
  if (status === "listed") {
    console.log(`  ${name}`);
    return;
  }
  if (status === "skipped" && (OPTS.only || OPTS.skip)) return; // noise
  const mark = { FAIL: "x", XPASS: "!", XFAIL: "~", ok: "+" }[status] || "-";
  console.log(`  ${mark} ${status.toUpperCase()} (${ms} ms)`);
  if (err) console.log(`      ${String(err.message).split("\n").join("\n      ")}`);
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertEqual(actual, expected, what) {
  if (actual !== expected) {
    throw new Error(`${what}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function note(message) {
  console.log(`      note: ${message}`);
}

// --------------------------------------------------------------------------------------------
// browser helpers (signup / login / logout), selectors as in the other scripts/playwright_*.js
// --------------------------------------------------------------------------------------------

async function fillLoginForm(page, email, password) {
  const usernameField = page.locator('input[name="username"]');
  await usernameField.waitFor({ timeout: 25000 });
  if (await usernameField.isEnabled().catch(() => false)) await usernameField.fill(email);
  await page.fill('input[name="currentPassword"]', password);
  await page.click("#login-form-button");
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(1500);
}

async function signUp(page) {
  const email = `pw-sess-${Math.random().toString(36).slice(2, 10)}@example.com`;
  const password = OPTS.password;
  try {
    return await signUpSteps(page, email, password);
  } catch (err) {
    await page.screenshot({ path: `${SCREENSHOT_DIR}/session-signup-failed.png`, fullPage: true }).catch(() => {});
    const text = await page.locator("body").innerText().catch(() => "");
    console.log(`      at ${page.url()} after signup failure:
${text.split("\n").slice(0, 25).join("\n")}`);
    throw err;
  }
}

async function signUpSteps(page, email, password) {

  await page.goto(`${URLS.signup}/`, { waitUntil: "networkidle" });
  await page.waitForSelector("#register-with-name", { timeout: 25000 });
  const showForm = page.locator("#register-with-name").getByRole("button", { name: /show form/i });
  if (await visibleWithin(showForm, 4000)) await showForm.click();
  await page.waitForSelector("#register-form", { timeout: 25000 });
  await page.fill('input[name="given_name"]', "Playwright");
  await page.fill('input[name="surname"]', "Sessiontest");
  await page.fill('input[name="email"]', email);
  await page.click("#register-button");

  // the captcha and the terms-of-use step come and go; wait for each before acting on it
  for (let i = 0; i < 8; i++) {
    if (await visibleWithin(page.locator("#captcha-form"), 5000)) {
      await page.fill('#captcha-form input[name="value"]', CAPTCHA_BACKDOOR_CODE);
      await page.click("#captcha-continue-button");
      continue;
    }
    if (await visibleWithin(page.locator("#accept-button"), 5000)) {
      await page.click("#accept-button");
      continue;
    }
    if (await visibleWithin(page.locator('input[name="v[0]"]'), 5000)) break;
  }

  await page.waitForSelector('input[name="v[0]"]', { timeout: 25000 });
  const codeUrl = `${URLS.signup}/services/signup/get-code?email=${encodeURIComponent(email)}`;
  const code = (await (await page.request.get(codeUrl)).text()).trim();
  if (!/^\d{6}$/.test(code)) throw new Error(`magic-cookie get-code backdoor returned "${code}"`);
  for (let i = 0; i < 6; i++) await page.fill(`input[name="v[${i}]"]`, code[i]);
  await page.click("#response-code-ok-button");

  await page.waitForSelector("#register-password", { timeout: 25000 });
  await page.getByRole("button", { name: /show form/i }).click();

  if (password) {
    // "Create your own password" - the field is validated client side against nothing but length
    await page.click("#custom-pw");
    await page.fill('input[name="newPassword"]', password);
  } else {
    // the generated password is fetched asynchronously; wait for it to show up before repeating it
    await page.waitForFunction(
      () => {
        const el = document.querySelector("#copy-new-password");
        return Boolean(el && el.value.trim().length > 0);
      },
      undefined,
      { timeout: 30000 },
    );
    const suggested = await page.inputValue("#copy-new-password");
    password = suggested;
    await page.fill('input[name="newPassword"]', suggested);
  }
  await page.click("#new-password-button", { timeout: 15000 });
  await page.waitForSelector("#finished-button", { timeout: 25000 });
  await page.click("#finished-button");
  await page.waitForLoadState("networkidle");

  return { email, password };
}

async function isLoggedIn(page) {
  return visibleWithin(page.locator("#logout"), 8000);
}

async function logIn(page, email, password) {
  await page.goto(`${URLS.html}/profile/`, { waitUntil: "networkidle" });
  if (await isLoggedIn(page)) return note("already logged in");
  // the landing page "log in" button goes to /start, which starts an IdP authentication
  if (await visibleWithin(page.locator("#login-button"), 6000)) {
    await page.click("#login-button");
  } else if (await visibleWithin(page.locator("#login"), 4000)) {
    await page.click("#login");
  }
  await fillLoginForm(page, email, password);
}

async function logOutThroughUi(page) {
  await page.waitForSelector("#logout", { timeout: 25000 });
  await page.click("#logout");
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(2000);
}

/**
 * A logged-in session for `eppn`, created through the apps' own session code, plus a browser
 * context carrying its cookie. Lets each concurrency test start from a known session state.
 */
async function sessionContext(browser, eppn) {
  const created = probe("create", eppn);
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  await context.addCookies([
    { name: SESSION_COOKIE, value: created.cookie, domain: ".eduid.docker", path: "/", secure: true },
    { name: MAGIC_COOKIE_NAME, value: MAGIC_COOKIE_VALUE, domain: ".eduid.docker", path: "/", secure: true },
  ]);
  return { context, cookie: created.cookie, sessionId: created.session_id };
}


// --------------------------------------------------------------------------------------------
// the suite
// --------------------------------------------------------------------------------------------

async function suite(browser) {
  const user = { email: OPTS.email, password: OPTS.password };
  const main = { context: null, page: null };

  /** One real account, one real login, shared by the tests that need a logged in browser. */
  async function ensureUser() {
    if (user.eppn) return;
    main.context = main.context || (await browser.newContext({ ignoreHTTPSErrors: true }));
    await main.context.addCookies([
      { name: MAGIC_COOKIE_NAME, value: MAGIC_COOKIE_VALUE, domain: ".eduid.docker", path: "/", secure: true },
    ]);
    main.page = main.page || (await main.context.newPage());
    main.page.setDefaultTimeout(60000);

    if (!user.email && OPTS.accountFile && fs.existsSync(OPTS.accountFile)) {
      const saved = JSON.parse(fs.readFileSync(OPTS.accountFile, "utf8"));
      if (saved.email && saved.password) {
        user.email = saved.email;
        user.password = saved.password;
        note(`reusing the account from ${OPTS.accountFile}`);
      }
    }
    if (!user.email) {
      const created = await signUp(main.page);
      user.email = created.email;
      user.password = created.password;
      if (OPTS.accountFile) fs.writeFileSync(OPTS.accountFile, JSON.stringify({ email: user.email, password: user.password }));
    }
    await logIn(main.page, user.email, user.password);
    assert(await isLoggedIn(main.page), `login of ${user.email} did not result in a logged in dashboard`);

    user.cookie = await cookieValue(main.context);
    assert(user.cookie, "no session cookie after login");
    const stored = readSession(user.cookie);
    assert(stored.exists, "no backend session after login");
    assertEqual(stored.data.common?.is_logged_in, true, "session.common.is_logged_in after login");
    assert(stored.data.common?.eppn, "no session.common.eppn after login");
    user.eppn = stored.data.common.eppn;
    user.sessionId = stored.session_id;
    note(`account ${user.email} / eppn ${user.eppn} / session ${user.sessionId.slice(0, 12)}...`);
  }

  // ==========================================================================================
  // A. session lifecycle
  // ==========================================================================================

  await test("lifecycle: first contact creates the backend session", async () => {
    const context = await browser.newContext({ ignoreHTTPSErrors: true });
    const page = await context.newPage();

    const resp = await context.request.get(EP.jsconfig);
    assert(resp.ok(), `jsconfig config request failed: ${resp.status()}`);
    const csrf = (await resp.json()).payload.csrf_token;
    assert(csrf, "no csrf_token in the jsconfig response");

    const cookie = (await context.cookies(URLS.dashboard)).find((c) => c.name === SESSION_COOKIE);
    assert(cookie, `no ${SESSION_COOKIE} cookie set on the first request`);
    assertEqual(cookie.domain, ".eduid.docker", "cookie domain (one cookie for every eduID webapp)");
    assertEqual(cookie.path, "/", "cookie path");
    assert(cookie.secure, "cookie must be Secure (config session_cookie_secure: yes)");
    assert(cookie.httpOnly, "cookie must be HttpOnly (config session_cookie_httponly: yes)");
    assertEqual(cookie.sameSite, "None", "cookie SameSite (config session_cookie_samesite: None)");
    assert(/^a[A-Z2-7=]+$/.test(cookie.value), `cookie is not an 'a' + base32 token: ${cookie.value.slice(0, 24)}`);

    const stored = readSession(cookie.value);
    assert(stored.exists, "the session belonging to the cookie was not stored in Redis");
    assert(stored.ttl > SESSION_TTL - 300 && stored.ttl <= SESSION_TTL, `unexpected ttl ${stored.ttl}`);
    assertEqual(stored.data._csrft_, csrf, "the csrf_token handed out must be the one in the session");

    // neither the browser nor anyone reading Redis may see the session contents in the clear
    await page.goto(`${URLS.html}/`, { waitUntil: "domcontentloaded" });
    const visibleToJs = await page.evaluate(() => document.cookie);
    assert(!visibleToJs.includes(SESSION_COOKIE), "session cookie is visible to JavaScript");
    const raw = probe("raw", cookie.value);
    assert(raw.raw.startsWith('{"v2"'), `unexpected stored format: ${raw.raw}`);
    assert(!raw.raw.includes(csrf), "session data is stored unencrypted in Redis");

    await context.close();
  });

  await test("lifecycle: sign up and log in", ensureUser);

  await test("lifecycle: the one session is shared by every webapp", async () => {
    await ensureUser();
    const keysBefore = probe("keys").keys;

    for (const url of [EP.allUserData, EP.credentials, EP.authnStatus, EP.jsconfig, EP.suggestedPassword]) {
      const resp = await main.context.request.get(url);
      assert(resp.status() < 500, `${url} answered ${resp.status()}`);
    }

    const data = (await (await main.context.request.get(EP.allUserData)).json()).payload;
    assertEqual(data.eppn, user.eppn, "personal data belongs to the logged in user");

    assertEqual(await cookieValue(main.context), user.cookie, "the cookie must not rotate between webapps");
    const created = probe("keys").keys.filter((k) => !keysBefore.includes(k));
    assertEqual(created.length, 0, `webapps minted their own sessions: ${created.join(", ")}`);
    assert(probe("exists", user.cookie).exists, "the login session key is gone");
  });

  await test("lifecycle: a request that changes nothing renews the ttl", async () => {
    await ensureUser();
    probe("expire", user.cookie, 300);
    assert(probe("ttl", user.cookie).ttl <= 301, "ttl was not shortened, the test cannot show a renewal");

    const resp = await main.context.request.get(EP.allUserData);
    assert(resp.ok(), `read-only request failed: ${resp.status()}`);

    const ttl = probe("ttl", user.cookie).ttl;
    assert(ttl > SESSION_TTL - 300, `ttl not renewed by a read-only request: ${ttl}s left of ${SESSION_TTL}`);
    assertEqual(await cookieValue(main.context), user.cookie, "ttl renewal must not rotate the session id");
    const stored = readSession(user.cookie);
    assertEqual(stored.data.common?.eppn, user.eppn, "session must still hold the login state");
    note(`ttl renewed from 300s to ${ttl}s`);
  });

  await test("lifecycle: the csrf token is session state, not client state", async () => {
    await ensureUser();

    const csrf = (await (await main.context.request.get(EP.jsconfig)).json()).payload.csrf_token;
    const good = await postJson(main.context, EP.userLanguage, { csrf_token: csrf, language: "en" });
    assert(good.ok(), `POST with the sessions csrf token failed: ${good.status()} ${await good.text()}`);

    // a second writer replaces the token in the session; the token the client holds must now fail
    probe("setpath", user.cookie, "_csrft_", JSON.stringify("rotated-by-another-writer"));
    const stale = await postJson(main.context, EP.userLanguage, { csrf_token: csrf, language: "en" });
    const staleBody = await stale.json();
    assert(staleBody.payload?.error, `stale csrf token was accepted: ${JSON.stringify(staleBody)}`);

    const fresh = (await (await main.context.request.get(EP.jsconfig)).json()).payload.csrf_token;
    assertEqual(fresh, "rotated-by-another-writer", "the session, not the client, decides the csrf token");
    note("csrf token is validated against the backend session");
  });

  await test("lifecycle: an expired session gives 401, never a 500", async () => {
    await ensureUser();
    const { context, cookie } = await sessionContext(browser, user.eppn);
    try {
      assert(readSession(cookie).exists, "the test session was not created");
      probe("expire", cookie, 1);
      await sleep(2000);
      assertEqual(probe("ttl", cookie).ttl, -2, "the test session should have expired by now");

      const resp = await context.request.get(EP.allUserData);
      assert(resp.status() < 500, `expired session produced ${resp.status()}`);
      assertEqual(resp.status(), 401, "an expired session must be answered with 401 (authn middleware)");
      assert((await resp.text()).toLowerCase().includes("authentication required"), "unexpected 401 body");
      assertEqual(await cookieValue(context), cookie, "an expired session must not rotate the cookie");
      const stored = readSession(cookie);
      assert(!stored.exists || !stored.data.common?.eppn, "expired session came back with login state");
    } finally {
      await context.close();
    }
  });

  await test("lifecycle: a tampered cookie cannot borrow someone elses session", async () => {
    await ensureUser();
    const { context, cookie } = await sessionContext(browser, user.eppn);
    try {
      // flip one character of the signature part; the session id part is kept identical
      const chars = cookie.split("");
      const idx = chars.length - 12;
      chars[idx] = chars[idx] === "A" ? "B" : "A";
      const tampered = chars.join("");
      assert(tampered !== cookie, "could not tamper with the cookie");

      await context.addCookies([{ name: SESSION_COOKIE, value: tampered, domain: ".eduid.docker", path: "/", secure: true }]);
      const response = await context.request.get(EP.allUserData);
      assert(response.status() < 500, `tampered cookie produced ${response.status()}`);
      assertEqual(response.status(), 401, "a cookie with a broken signature must not authenticate");
      const body = await response.json();
      assert(!JSON.stringify(body).includes(user.eppn), "answered with the victims personal data");
      note(`tampered cookie rejected with ${response.status()}`);
    } finally {
      await context.close();
    }
  });

  await test("lifecycle: parallel requests across webapps keep the session consistent", async () => {
    await ensureUser();
    const urls = [EP.allUserData, EP.credentials, EP.authnStatus, EP.jsconfig, EP.suggestedPassword];
    for (let round = 0; round < 3; round++) {
      const responses = await Promise.all(urls.map((url) => main.context.request.get(url)));
      const bad = responses.filter((r) => r.status() >= 500);
      assert(bad.length === 0, `${bad.length} of ${responses.length} parallel requests failed with 5xx`);
    }
    const stored = readSession(user.cookie);
    assertEqual(stored.data.common?.eppn, user.eppn, "login state lost after parallel requests");
    assertEqual(stored.data.common?.is_logged_in, true, "is_logged_in lost after parallel requests");
  });

  // ==========================================================================================
  // B. concurrency: a sibling writer commits while a request is in flight
  // ==========================================================================================

  const CONFLICT_LOG = "failed because it has been changed by someone else";
  const SWALLOW_LOG = "all safe to lose";
  const FATAL_LOG = "failing the request";

  await test("concurrency: readiness - can freeze MongoDB to make the races deterministic", async () => {
    if (!OPTS.chaos) throw new Skip("needs docker pause on the mongodb container (--no-chaos)");
    await ensureUser();
    await withFrozenMongo(async () => {
      assert(containerPaused(MONGO_CONTAINER), `${MONGO_CONTAINER} is not paused`);
    });
    note(`MongoDB freezing works; the concurrency tests below are deterministic, not timing-luck`);
  });

  /**
   * Run inside withFrozenMongo(): fire the request, confirm it is stuck on MongoDB, let the
   * sibling writer change the session, and hand back the still-pending response so the caller can
   * await it *after* MongoDB thaws. (Awaiting it here would just run it into a gateway timeout,
   * and returning it from an async function would await it too - hence the wrapper object.)
   */
  async function stageRacingRequest(cookieRef, context, siblingWrite, deletesSession) {
    assert(readSession(cookieRef).exists, "the backend session must exist before the request is fired");
    const response = context.request.get(EP.allUserData, { timeout: 60000 });
    const settledFirst = await Promise.race([
      response.then((r) => `settled:${r.status()}`),
      sleep(1500).then(() => "pending"),
    ]);
    assertEqual(
      settledFirst,
      "pending",
      "the request must still be in flight (stalled in front of MongoDB) when the sibling writes",
    );
    await siblingWrite(cookieRef);
    if (!deletesSession) {
      assert(readSession(cookieRef).exists, "the sibling write must leave a session to conflict with");
    }
    return { response };
  }

  async function concurrencyTest({ title, prepare, siblingWrite, deletesSession, expectStatus, expectLog, expectFatal }) {
    await test(title, async () => {
      if (!OPTS.chaos) throw new Skip("needs docker pause on the mongodb container (--no-chaos)");
      await ensureUser();
      const t0 = Date.now();
      const { context, cookie } = await sessionContext(browser, user.eppn);
      try {
        if (prepare) await prepare(cookie);
        // NB: only the staging (firing the request + the sibling write) happens while MongoDB is
        // frozen. Awaiting the response inside that block would run it into the gateway timeout.
        let pending;
        await withFrozenMongo(async () => {
          pending = await stageRacingRequest(cookie, context, siblingWrite, deletesSession);
        });
        const response = await pending.response;

        const log = quiet(sessionLog("personal_data", cookie));
        assert(
          log.includes(CONFLICT_LOG),
          `the write conflict was not detected at all ("${CONFLICT_LOG}"). Session log lines:\n${log.slice(-2500)}`,
        );
        assertEqual(
          response.status(),
          expectStatus,
          `${expectFatal ? "a fatal conflict must fail the request" : "a harmless loss must be swallowed"}; ` +
            `log tail:\n${log.slice(-2000)}`,
        );
        if (expectLog) {
          const wanted = Array.isArray(expectLog) ? expectLog : [expectLog];
          assert(
            wanted.some((w) => log.includes(w)),
            `the conflict should be classified as one of ${JSON.stringify(wanted)}; session log lines:\n${log.slice(-2500)}`,
          );
        }
        if (expectFatal) {
          assert(
            log.includes(FATAL_LOG),
            `a fatal conflict must log that it fails the request; session log lines:\n${log.slice(-2500)}`,
          );
        }
        note(`verdict ${response.status()} as expected (${Date.now() - t0} ms)`);
      } finally {
        await context.close();
      }
    });
  }

  await concurrencyTest({
    title:
      "concurrency: an in-flight request is failed when a sibling logout deletes the session",
    siblingWrite: async (cookie) => probe("delete", cookie),
    deletesSession: true,
    expectStatus: 500,
    expectLog: ["generation changed", "deleted or cleared by other writer"],
    expectFatal: true,
  });

  await concurrencyTest({
    title:
      "concurrency: an in-flight request is failed when a sibling logout clears the auth state",
    siblingWrite: async (cookie) => probe("setns", cookie, "common", "null"),
    expectStatus: 500,
    expectLog: ["generation changed", "deleted or cleared by other writer"],
    expectFatal: true,
  });

  await concurrencyTest({
    title:
      "concurrency: a request that writes nothing survives a benign sibling change (swallowed)",
    siblingWrite: async (cookie) => probe("setpath", cookie, "common.preferred_language", JSON.stringify("sv")),
    expectStatus: 200,
    expectLog: SWALLOW_LOG,
    expectFatal: false,
  });

  await concurrencyTest({
    title:
      "concurrency: a lost write that is not on the safe-to-lose list fails the request",
    // without a csrf token in the session, the response marshalling writes one -> our own write
    prepare: async (cookie) => probe("delpath", cookie, "_csrft_"),
    siblingWrite: async (cookie) => probe("setpath", cookie, "common.preferred_language", JSON.stringify("sv")),
    expectStatus: 500,
    expectLog: "not all changes are safe to lose",
    expectFatal: true,
  });

  await concurrencyTest({
    title:
      "concurrency: a sibling reset that changes only the session generation fails the request",
    // A logout resets the session; nothing but the generation marker has to differ, so no
    // key-path comparison can tell that the session this request belongs to is gone.
    siblingWrite: async (cookie) => probe("regen", cookie),
    expectStatus: 500,
    expectLog: "generation changed",
    expectFatal: true,
  });

  await concurrencyTest({
    title:
      "concurrency: a sibling logout (reset, new generation) fails an in-flight request",
    siblingWrite: async (cookie) => probe("reset", cookie),
    expectStatus: 500,
    expectLog: "generation changed",
    expectFatal: true,
  });

  await test(
    "concurrency: parallel first requests on a brand new session",
    async () => {
    await ensureUser();
    const { context, cookie } = await sessionContext(browser, user.eppn);
    try {
      // both apps answer with a csrf_token and neither has one yet, so both write to the session
      probe("delpath", cookie, "_csrft_");
      const responses = await Promise.all([
        context.request.get(EP.allUserData, { timeout: 60000 }),
        context.request.get(EP.jsconfig, { timeout: 60000 }),
        context.request.get(EP.credentials, { timeout: 60000 }),
        context.request.get(EP.authnStatus, { timeout: 60000 }),
        context.request.get(EP.suggestedPassword, { timeout: 60000 }),
      ]);
      const failed = responses.filter((r) => r.status() >= 500);
      const stored = readSession(cookie);
      if (failed.length) {
        note(`session log lines:\n${quiet(sessionLog("personal_data", cookie)).slice(-1500)}`);
      }
      assertEqual(
        failed.length,
        0,
        `${failed.length} of ${responses.length} parallel first requests failed with 5xx: a lost write of ` +
          `"_csrft_" is not in session_safe_to_lose_paths, so the loser of the race is failed. Either add it ` +
          `(and stop handing the client a token that never made it into the session) or generate the token ` +
          `without writing it when the session already has one.`,
      );
      assert(stored.data._csrft_, "no csrf token was written by any of the parallel requests");
      assertEqual(stored.data.common?.eppn, user.eppn, "login state lost in a parallel first load");
    } finally {
      await context.close();
    }
    },
    {
      xfail:
        "two webapps generating the csrf token for the same brand new session: when the writes " +
        "overlap the loser is failed with 500, because a lost _csrft_ write is not on " +
        "session_safe_to_lose_paths (timing dependent - see the session log lines above)",
    },
  );

  await test("concurrency: a logout during a request storm cannot bring the login state back", async () => {
    await ensureUser();
    const { context, cookie } = await sessionContext(browser, user.eppn);
    try {
      const csrf = readSession(cookie).data._csrft_;
      const urls = [EP.allUserData, EP.credentials, EP.jsconfig, EP.authnStatus, EP.suggestedPassword];
      const inflight = [];
      for (let i = 0; i < 3; i++) for (const url of urls) inflight.push(context.request.get(url, { timeout: 60000 }));
      await sleep(150);

      const logout = await postJson(context, EP.idpLogout, { csrf_token: csrf });
      const logoutBody = await logout.json().catch(() => ({}));
      assertEqual(logoutBody.payload?.finished, true, "the logout did not go through: " + JSON.stringify(logoutBody));
      const logoutStatus = logout.status();
      assert(logoutStatus < 500, `the logout itself failed: ${logoutStatus} ${(await logout.text()).slice(0, 200)}`);

      const responses = await Promise.all(inflight);
      const failed = responses.filter((r) => r.status() >= 500);
      note(`${responses.length} requests raced the logout, ${failed.length} failed (5xx)`);

      const stored = readSession(cookie);
      assert(
        !stored.exists || !stored.data.common?.eppn,
        `an in-flight request resurrected the login state after logout: ${JSON.stringify(stored.data?.common)}`,
      );

      // and the user really is logged out afterwards - a clean 401, not a 500
      const after = await context.request.get(EP.allUserData);
      assertEqual(after.status(), 401, "the session must be logged out and rejected with 401");
    } finally {
      await context.close();
    }
  });

  // ==========================================================================================
  // C. logout, in the browser
  // ==========================================================================================

  await test("lifecycle: logging out in one tab logs the other tab out", async () => {
    await ensureUser();
    const otherTab = await main.context.newPage();
    await otherTab.goto(`${URLS.html}/profile/`, { waitUntil: "networkidle" });
    assert(await isLoggedIn(otherTab), "the second tab is not logged in");

    await logOutThroughUi(main.page);

    const stored = readSession(user.cookie);
    assert(
      !stored.exists || !stored.data.common?.eppn,
      `the backend session still holds the login after logout: ${JSON.stringify(stored.data?.common)}`,
    );

    await otherTab.goto(`${URLS.html}/profile/`, { waitUntil: "networkidle" });
    assert(
      !(await visibleWithin(otherTab.locator("#logout"), 8000)),
      "the second tab still shows a logged in dashboard after logout in the first tab",
    );

    const rejected = await main.context.request.get(EP.allUserData);
    assertEqual(rejected.status(), 401, "after logout the API must reject the old session");
    await otherTab.screenshot({ path: `${SCREENSHOT_DIR}/session-02-logged-out.png`, fullPage: true });
    await otherTab.close();
  });

  await test("lifecycle: after a logout the IdP asks for a password again", async () => {
    await ensureUser();
    assert(main.page, "the logout test above owns the browser page");
    await main.page.goto(`${URLS.html}/`, { waitUntil: "networkidle" });
    assert(!(await isLoggedIn(main.page)), "still logged in");
    if (await visibleWithin(main.page.locator("#login-button"), 8000)) await main.page.click("#login-button");
    await main.page.waitForSelector('input[name="username"]', { timeout: 25000 });
    note("the SSO session is gone: the IdP wants a password again");
    await main.page.screenshot({ path: `${SCREENSHOT_DIR}/session-03-login-required.png`, fullPage: true });
    await main.page.goto(`${URLS.html}/`, { waitUntil: "networkidle" });
  });

  await test("lifecycle: logging in again yields a usable session", async () => {
    assert(user.email && user.password, "the account from the signup/login test is needed");
    const page = await main.context.newPage();
    page.setDefaultTimeout(60000);
    await logIn(page, user.email, user.password);
    assert(await isLoggedIn(page), "logging in again did not work");

    const cookie = await cookieValue(main.context);
    const stored = readSession(cookie);
    assertEqual(stored.data.common?.eppn, user.eppn, "the new session must carry the login state");
    assertEqual(stored.data.common?.is_logged_in, true, "is_logged_in must be true after logging in");
    assert(stored.ttl > SESSION_TTL - 300, `unexpected ttl for the new session: ${stored.ttl}`);
    user.cookie = cookie;
    await page.close();
  });
}

// --------------------------------------------------------------------------------------------
// runner
// --------------------------------------------------------------------------------------------

// never leave the dev stack frozen, whatever happens to this script
process.on("exit", () => {
  try {
    if (containerPaused(MONGO_CONTAINER)) docker(["unpause", MONGO_CONTAINER]);
  } catch (e) {
    /* nothing to clean up */
  }
});

(async () => {
  const browser = await chromium.launch({
    headless: !process.env.HEADED,
    slowMo: process.env.HEADED ? 50 : 0,
    chromiumSandbox: false,
    args: ["--no-sandbox", "--no-zygote", "--disable-dev-shm-usage"],
  });
  let exitCode = 1;
  try {
    // make scripts/session_probe.py available inside the webapp container
    execFileSync("docker", ["cp", `${__dirname}/session_probe.py`, `${PROBE_CONTAINER}:/tmp/session_probe.py`]);
    console.log(`eduID session handling e2e (${OPTS.only ? `only "${OPTS.only}"` : "all tests"})`);
    await suite(browser);
    console.log("\n" + "-".repeat(70));
    for (const r of results) {
      if (r.status === "ok") console.log(`  PASS     ${r.name}`);
      else if (r.status === "FAIL") console.log(`  FAIL     ${r.name}`);
      else if (r.status === "XFAIL") console.log(`  XFAIL    ${r.name} (known gap)`);
      else if (r.status === "XPASS") console.log(`  XPASS    ${r.name} (known gap appears fixed)`);
    }
    const passed = results.filter((r) => r.status === "ok").length;
    const skipped = results.filter((r) => r.status === "skipped").length;
    const known = results.filter((r) => r.status === "XFAIL" || r.status === "XPASS").length;
    console.log(
      `\n${passed} passed, ${failures} failed, ${known} known-gap, ${skipped} skipped of ${results.length}`,
    );
    exitCode = failures ? 1 : 0;
  } catch (err) {
    console.error("SUITE ABORTED:", err);
    exitCode = 1;
  } finally {
    if (OPTS.keepOpen) {
      console.log(`keeping the browser open for ${OPTS.keepOpen} ms`);
      await sleep(OPTS.keepOpen);
    }
    await browser.close();
  }
  process.exit(exitCode);
})();
