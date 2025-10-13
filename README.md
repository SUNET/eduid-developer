# eduID Developer Environment Setup

This repository provides a complete local development environment for eduID using Docker containers.

## Table of Contents

- [Prerequisites](#prerequisites)
- [First-Time Setup](#first-time-setup)
- [Running the Environment](#running-the-environment)
- [Development Workflow](#development-workflow)
- [Services and URLs](#services-and-urls)
- [Makefile Commands](#makefile-commands)
- [Troubleshooting](#troubleshooting)
- [Alternative: Vagrant Setup](#alternative-vagrant-setup)

## Prerequisites

Before starting, ensure you have the following installed:

- **Docker** (version 20.10 or later)
- **Docker Compose plugin** (v2.x - the `docker compose` command, not the legacy `docker-compose`)
- **Make**
- **Git**
- A text editor for configuration files

To verify your Docker installation:

    docker --version
    docker compose version

**Note:** This guide assumes you're using Linux. For other operating systems, see the [Vagrant Setup](#alternative-vagrant-setup) section.

## First-Time Setup

### 1. Clone the Repository

    git clone git@github.com:SUNET/eduid-developer.git
    cd eduid-developer

### 2. Set Up TLS Certificates

Before starting the environment for the first time, generate the TLS certificates:

    cd pki
    ./create_pki.sh
    cd ..

This creates a local Certificate Authority (CA) and certificates for all services. You'll need to import the root CA certificate (`pki/rootCA.crt`) into your browser's certificate store (in the Authorities section).

**Security Note:** Keep `pki/rootCA.key` private as it can be used for man-in-the-middle attacks against your development machine.

### 3. Configure Source Directories (Optional)

For live code reloading, set up symlinks to your local eduID source repositories in the `sources/` directory.

**Important:** Don't use `~` in `EDUID_SRC_PATH` as it may be expanded as a different user.

Example setup:

    export EDUID_SRC_PATH=/home/yourusername/projects
    cd sources
    ln -s $EDUID_SRC_PATH/eduid-backend ./eduid-backend
    ln -s $EDUID_SRC_PATH/eduid-front ./eduid-front
    ln -s $EDUID_SRC_PATH/eduid-html ./eduid-html

The compose configuration will automatically mount available source directories into the containers. Both the main package and its eduID dependencies will be mounted for each container.

## Running the Environment

### Starting the Environment

Start all containers (this will modify `/etc/hosts` and may ask for sudo password):

    make start

The first time you run this:

- It will add entries to `/etc/hosts` for all eduID services (requires sudo)
- It will pull all required Docker images from the registry
- It may take several minutes to start all services

### Stopping the Environment

    make stop

### Checking Running Containers

    docker ps

### Restarting Services

To restart services without stopping everything:

    make up

## Development Workflow

### Viewing Logs

All logs from webapps are kept in a shared data volume called `eduidlogdata`.

For a quick tail of logs for a specific service:

    ./bin/tailf signup
    ./bin/tailf dashboard

To get a shell with all mounted log files:

    make show_logs

Log files are available in `/var/log/eduid` within this container.

### Live Code Reloads

When source directories are properly symlinked in the `sources/` directory, changes to your local code will automatically reload in the running containers. The containers are configured to:

- Mount your local source tree in `/opt/eduid/src`
- Add the source paths to `PYTHONPATH`
- Run with the `--reload` flag for automatic reloading

This applies to both the main package and its eduID dependencies.

### Accessing the Database

#### MongoDB

To access the MongoDB shell:

    make mongodb_cli

Direct connection:

    mongodb://mongodb.eduid.docker

#### Redis

Direct connection:

    redis://redis.eduid.docker

#### Neo4j

Direct connection:

    neo4j://neo4jdb.eduid.docker

### Building Frontend Bundles

If you need to rebuild the frontend JavaScript bundles:

    make build_frontend_bundle
    make build_managed_account_bundle

### Authentication Backend

Turq (a mock HTTP server) is used to fake 'OK' responses to all calls to the VCCS authentication backend during development.

Access Turq at: <http://turq.eduid.docker:13085/+turq/>

## Services and URLs

The development environment runs the following services:

| Service          | URL                                    | Description                 |
| ---------------- | -------------------------------------- | --------------------------- |
| Signup           | <https://signup.eduid.docker/>           | User registration           |
| Dashboard        | <https://dashboard.eduid.docker/>        | User dashboard              |
| HTML/Landing     | <https://html.eduid.docker/>             | Static HTML pages           |
| Support          | <https://support.eduid.docker/>          | Support interface           |
| IdP              | <https://idp.eduid.docker/>              | Identity Provider           |
| API              | <https://api.eduid.docker/>              | API endpoints               |
| Managed Accounts | <https://managed-accounts.eduid.docker/> | Managed accounts interface  |
| BankID           | <https://bankid.eduid.docker/>           | BankID integration          |
| IdP Proxy        | <https://idpproxy.eduid.docker/>         | IdP proxy                   |
| Turq (Mock)      | <http://turq.eduid.docker:13085/+turq/>  | Mock authentication backend |

All services use HTTPS except Turq. Make sure you've imported the root CA certificate to avoid browser warnings.

## Makefile Commands

### Starting and Stopping

| Command      | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| `make start` | Start all containers (modifies /etc/hosts, may request sudo) |
| `make stop`  | Stop all containers                                          |
| `make up`    | Start any non-running containers                             |
| `make pull`  | Pull latest Docker images                                    |

### Debugging and Development

| Command                 | Description                                           |
| ----------------------- | ----------------------------------------------------- |
| `make show_logs`        | Open shell with log volumes mounted at /var/log/eduid |
| `make show_appdata`     | Open shell with app data volume mounted at /appdata   |
| `make mongodb_cli`      | Open MongoDB shell (mongosh)                          |
| `./bin/tailf <service>` | Tail logs for a specific service                      |

### Building

| Command                             | Description                          |
| ----------------------------------- | ------------------------------------ |
| `make build_frontend_bundle`        | Build the frontend JavaScript bundle |
| `make build_managed_account_bundle` | Build the managed accounts bundle    |
| `make frontend_npm_start`           | Run frontend development server      |

### Version Management

| Command                                      | Description                                |
| -------------------------------------------- | ------------------------------------------ |
| `make developer_release VERSION=<timestamp>` | Update all service versions in compose.yml |

## Troubleshooting

### Port Conflicts

If you see errors about ports already in use, make sure no other services are running on the same ports. Check with:

    sudo netstat -tlnp | grep LISTEN

### Permission Errors

If you get permission errors with Docker:

- Ensure your user is in the `docker` group: `sudo usermod -aG docker $USER`
- Log out and back in for group changes to take effect

### Cannot Connect to Services

1. Verify /etc/hosts entries were added correctly:

   ```
   grep eduid.docker /etc/hosts
   ```

2. Check that containers are running:

   ```
   docker ps
   ```

3. Check container logs:

   ```
   docker compose -f eduid/compose.yml logs <service-name>
   ```

### Building Docker Images Locally

All containers should be built by ci.sunet.se and will be pulled automatically. If you need to build Docker containers locally, use the Dockerfiles in the separate repository:

    git clone git@github.com:SUNET/eduid-dockerfiles.git
    cd eduid-dockerfiles
    ./build <service-name>

### Network Issues Between Docker and Vagrant

If you want to run both Docker and Vagrant environments, you need to reset your networking before switching:

**For Docker:**

    docker network rm eduid_dev

**For Vagrant (VirtualBox):**

Open VirtualBox, go to File → Host Network Manager and remove the network 172.16.10.0/24.

### ORCID Configuration

To use ORCID integration, you need to obtain OIDC secrets for the ORCID sandbox from a colleague.

Create a file named `oidc_client_creds.yaml` in `eduid-orcid/etc/`:

```yaml
---
CLIENT_REGISTRATION_INFO:
  client_id: the_client_id
  client_secret: the_client_secret
```

### Signup Confirmation Emails

When testing user signup, the confirmation email content will be available in the log files rather than being sent to an actual email address. Use `./bin/tailf signup` to see the confirmation links.

## Alternative: Vagrant Setup

For development on non-Linux systems (macOS, Windows), you can use Vagrant with VirtualBox.

### Prerequisites

- VirtualBox: <https://www.virtualbox.org/>
- Vagrant: <https://www.vagrantup.com/>

### Setup

1. Create a file named `vagrant.yml` in the repository root:

```yaml
local_paths:
  eduid_front: "/path/to/eduid-front"
  eduid_html: "/path/to/eduid-html"
vm:
  cpus: 2
  memory: 4096
  disksize: "20GB"
```

2. Start the Vagrant VM (only needed once per session):

   $ make vagrant_run

3. Start the containers inside the VM:

   $ make vagrant_start

4. Connect to the Vagrant VM:

   $ make vagrant_ssh

### Vagrant Commands

| Command                    | Description                        |
| -------------------------- | ---------------------------------- |
| `make vagrant_run`         | Start Vagrant VM                   |
| `make vagrant_start`       | Start all containers in VM         |
| `make vagrant_stop`        | Stop all containers in VM          |
| `make vagrant_halt`        | Stop containers and halt VM        |
| `make vagrant_ssh`         | SSH into the VM                    |
| `make vagrant_up`          | Start non-running containers in VM |
| `make vagrant_pull`        | Pull latest images in VM           |
| `make vagrant_show_logs`   | View logs in VM                    |
| `make vagrant_mongodb_cli` | MongoDB shell in VM                |
| `make vagrant_destroy`     | Destroy the VM completely          |

**Note:** The PKI certificate creation script runs automatically on `make vagrant_run`.

---

## Contributing

When making changes to the environment:

- Test both Docker and Vagrant setups if possible
- Update this README with any new services or configuration requirements
