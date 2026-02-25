# AGENTS.md - AI Agent Guidelines for eduID Developer Environment

Guidelines for AI coding agents working in the eduID Developer repository.

## Project Overview

**eduid-developer** is a Docker-based local development environment for the eduID identity management system. This is an orchestration/infrastructure repository - not the application source code.

Key technologies: Docker Compose, HAProxy, MongoDB, Redis, Neo4j, Python (Flask/FastAPI), SAML2.

## Repository Structure

```
eduid-developer/
├── eduid/compose.yml       # Main Docker Compose configuration (~50 services)
├── config/config.yaml      # Centralized configuration for all services
├── sources/                # Symlinks to local source repositories
├── pki/                    # TLS certificates and local CA
├── eduid-*/                # Per-service configuration directories
├── *-haproxy/              # HAProxy configs for load balancing
├── mongodb/                # MongoDB configuration and scripts
├── scripts/                # Build and utility scripts
├── bin/                    # Helper utilities (tailf, etc.)
├── Makefile                # Build/run commands
└── start.sh / stop.sh      # Start/stop all containers
```

## Build/Run Commands

```bash
make start              # Start all containers (modifies /etc/hosts, requires sudo)
make stop               # Stop all containers
make up                 # Start any stopped containers
make pull               # Pull latest Docker images
./bin/tailf <service>   # Tail logs for a specific service (e.g., signup, dashboard)
make show_logs          # Shell with log volumes mounted at /var/log/eduid
make mongodb_cli        # Open MongoDB shell (mongosh)
```

## Services and URLs

| Service | URL |
|---------|-----|
| Signup | https://signup.eduid.docker/ |
| Dashboard | https://dashboard.eduid.docker/ |
| HTML/Landing | https://html.eduid.docker/ |
| IdP | https://idp.eduid.docker/ |
| API | https://api.eduid.docker/ |
| Support | https://support.eduid.docker/ |
| Managed Accounts | https://managed-accounts.eduid.docker/ |

## Source Code Development

The actual application code lives in separate repositories symlinked via `sources/`:
- `eduid-backend/` - Main Python backend (Flask, FastAPI, workers) - **has its own AGENTS.md**
- `eduid-front/` - React frontend
- `eduid-html/` - Static HTML pages

When source directories are symlinked, changes auto-reload (containers run with `--reload` flag).

> **Note:** For test commands, linting, and Python code style guidelines, see `sources/eduid-backend/AGENTS.md`

## Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):
```
feat(webapp): add new identity verification flow
fix(userdb): handle missing email gracefully
refactor(compose): simplify service dependencies
docs: update development setup instructions
chore: update Docker image versions
```

## First-Time Setup

1. Generate TLS certificates: `cd pki && ./create_pki.sh`
2. Import `pki/rootCA.crt` into browser certificate store
3. Symlink source repos in `sources/` directory
4. Run `make start` (requires sudo for /etc/hosts)
