#!/bin/bash
#
# Create users for the eduID local developer environment.
#

# -------------------------------------------------------------------------------------
#
# User eduid_signup, readWrite
#
for db in eduid_signup; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_signup"}) == 0) {
         db.createUser( { user: "eduid_signup", pwd: "eduid_signup_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_signup, read
#
for db in eduid_tou eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_signup"}) == 0) {
         db.createUser( { user: "eduid_signup", pwd: "eduid_signup_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_am, readWrite
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_am"}) == 0) {
         db.createUser( { user: "eduid_am", pwd: "eduid_am_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_am, read
#
for db in eduid_signup eduid_dashboard eduid_api eduid_idproofing_letter eduid_emails eduid_phones eduid_security eduid_oidc_proofing; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_am"}) == 0) {
         db.createUser( { user: "eduid_am", pwd: "eduid_am_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_dashboard, readWrite
#
for db in eduid_dashboard eduid_emails eduid_phones eduid_security; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_dashboard"}) == 0) {
         db.createUser( { user: "eduid_dashboard", pwd: "eduid_dashboard_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_dashboard, read
#
for db in eduid_am eduid_idp_authninfo; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_dashboard"}) == 0) {
         db.createUser( { user: "eduid_dashboard", pwd: "eduid_dashboard_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_phones, readWrite
#
for db in eduid_dashboard; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_phones"}) == 0) {
         db.createUser( { user: "eduid_phones", pwd: "eduid_phones_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_phones, read
#
for db in eduid_am eduid_idp_authninfo; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_phones"}) == 0) {
         db.createUser( { user: "eduid_phones", pwd: "eduid_phones_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_emails, readWrite
#
for db in eduid_dashboard; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_emails"}) == 0) {
         db.createUser( { user: "eduid_emails", pwd: "eduid_emails_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_emails, read
#
for db in eduid_am eduid_idp_authninfo; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_emails"}) == 0) {
         db.createUser( { user: "eduid_emails", pwd: "eduid_emails_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_security, readWrite
#
for db in eduid_dashboard; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_security"}) == 0) {
         db.createUser( { user: "eduid_security", pwd: "eduid_security_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_security, read
#
for db in eduid_am eduid_idp_authninfo; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_security"}) == 0) {
         db.createUser( { user: "eduid_security", pwd: "eduid_security_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_idp, readWrite
#
for db in eduid_idp eduid_idp_authninfo eduid_idp_pysaml2 eduid_actions; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idp"}) == 0) {
         db.createUser( { user: "eduid_idp", pwd: "eduid_idp_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_idp, read
#
for db in eduid_am eduid_tou; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idp"}) == 0) {
         db.createUser( { user: "eduid_idp", pwd: "eduid_idp_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_actions, readWrite
#
for db in eduid_tou; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_actions"}) == 0) {
         db.createUser( { user: "eduid_actions", pwd: "eduid_actions_pw", roles: ["readWrite"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_api, readWrite
#
for db in eduid_api; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_api"}) == 0) {
         db.createUser( { user: "eduid_api", pwd: "eduid_api_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_api, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_api"}) == 0) {
         db.createUser( { user: "eduid_api", pwd: "eduid_api_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_lookup_mobile, readWrite
#
for db in eduid_lookup_mobile; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_lookup_mobile"}) == 0) {
         db.createUser( { user: "eduid_lookup_mobile", pwd: "eduid_lookup_mobile_pw", roles: ["readWrite"] } );
      }
'
done


# -------------------------------------------------------------------------------------
#
# User eduid_actions, readWrite
#
for db in eduid_actions; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_actions"}) == 0) {
         db.createUser( { user: "eduid_actions", pwd: "eduid_actions_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_am, readWrite
#
for db in eduid_actions; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_am"}) == 0) {
         db.createUser( { user: "eduid_am", pwd: "eduid_am_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_actions, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_actions"}) == 0) {
         db.createUser( { user: "eduid_actions", pwd: "eduid_actions_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_idproofing_letter, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idproofing_letter"}) == 0) {
         db.createUser( { user: "eduid_idproofing_letter", pwd: "eduid_idproofing_letter_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_emails, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_emails"}) == 0) {
         db.createUser( { user: "eduid_emails", pwd: "eduid_emails_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_phones, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_phones"}) == 0) {
         db.createUser( { user: "eduid_phones", pwd: "eduid_phones_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_security, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_security"}) == 0) {
         db.createUser( { user: "eduid_security", pwd: "eduid_security_pw", roles: ["read"] } );
      }
'
done

# User eduid_actions, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_actions"}) == 0) {
         db.createUser( { user: "eduid_actions", pwd: "eduid_actions_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_oidc_proofing, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_oidc_proofing,"}) == 0) {
         db.createUser( { user: "eduid_oidc_proofing", pwd: "eduid_oidc_proofing_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_idproofing_letter, readWrite
#
for db in eduid_idproofing_letter; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idproofing_letter"}) == 0) {
         db.createUser( { user: "eduid_idproofing_letter", pwd: "eduid_idproofing_letter_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_emails, readWrite
#
for db in eduid_emails; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_emails"}) == 0) {
         db.createUser( { user: "eduid_emails", pwd: "eduid_emails_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_phones, readWrite
#
for db in eduid_phones; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_phones"}) == 0) {
         db.createUser( { user: "eduid_phones", pwd: "eduid_phones_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_security, readWrite
#
for db in eduid_security; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_security"}) == 0) {
         db.createUser( { user: "eduid_security", pwd: "eduid_security_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_oidc_proofing, readWrite
#
for db in eduid_oidc_proofing; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_oidc_proofing"}) == 0) {
         db.createUser( { user: "eduid_oidc_proofing", pwd: "eduid_oidc_proofing_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_authn, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_authn,"}) == 0) {
         db.createUser( { user: "eduid_authn", pwd: "eduid_authn_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_support, read
#
for db in eduid_am eduid_signup eduid_dashboard eduid_oidc_proofing eduid_idproofing_letter eduid_emails eduid_security eduid_api eduid_actions eduid_lookup_mobile eduid_tou eduid_idp eduid_idp_authninfo eduid_idp_pysaml2; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_support"}) == 0) {
         db.createUser( { user: "eduid_support", pwd: "eduid_support_pw", roles: ["read"] } );
      }
'
done
