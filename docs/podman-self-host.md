# Self-hosting Langfuse with Podman

This guide covers running Langfuse using **Podman** instead of Docker—for example on a **Raspberry Pi 4** or any Debian-based system where Podman is preferred.

## Prerequisites

- **Podman** installed (e.g. `sudo apt install podman` on Debian)
- **Podman Compose** (one of):
  - **`podman compose`** – Podman’s built-in Compose plugin (recommended), or
  - **`podman-compose`** – standalone (`pip install podman-compose` or from your distro)

The project’s **Makefile** detects whichever is available and uses it for all commands.

## Quick start

1. **Clone the repo** (if you haven’t already):
   ```bash
   git clone https://github.com/langfuse/langfuse.git
   cd langfuse
   ```

2. **Create and edit `.env`** (required for production; set your own secrets):
   ```bash
   cp .env.prod.example .env
   ```
   Edit `.env` and set at least:
   - `NEXTAUTH_SECRET` – e.g. `openssl rand -base64 32`
   - `SALT` – e.g. `openssl rand -base64 32`
   - `ENCRYPTION_KEY` – `openssl rand -hex 32`
   - `POSTGRES_PASSWORD`, `CLICKHOUSE_PASSWORD`, `REDIS_AUTH`, MinIO credentials (or keep defaults for a single-user / dev setup)

   For the Pi’s hostname or LAN IP, set `NEXTAUTH_URL` (e.g. `http://192.168.1.10:3000` or `http://langfuse.local:3000`).

3. **Start the stack**:
   ```bash
   make up
   ```
   Or explicitly: `make up` (same as `make`).

4. **Open the app** at `http://<your-pi-ip>:3000` (or the host/port you exposed).

5. **Stop everything** when needed:
   ```bash
   make down
   ```

## Makefile targets

| Target          | Description                                      |
|-----------------|--------------------------------------------------|
| `make` / `make up` | Start all services in the background (detached). |
| `make down`     | Stop and remove containers.                      |
| `make down-volumes` | Stop and remove containers **and volumes** (fresh state; data is lost). |
| `make restart`  | Run `down` then `up`.                            |
| `make logs`     | Follow logs of all services.                     |
| `make ps`       | List running containers.                         |
| `make pull`     | Pull latest images (useful before first `make up`). |
| `make help`     | Show targets and the compose command in use.    |

All of these use the same `docker-compose.yml` as the standard Docker Compose setup; only the runtime is Podman.

## Raspberry Pi 4 notes

- **Architecture**: Raspberry Pi 4 is typically **arm64**. The base images (Postgres, Redis, ClickHouse, MinIO) are multi-arch. Langfuse images (`langfuse/langfuse`, `langfuse/langfuse-worker`) may or may not publish arm64; if pull or run fails, check [Langfuse docs](https://langfuse.com/docs/deployment/self-host) for arm64 or build from source.
- **Resources**: The full stack (web, worker, Postgres, ClickHouse, Redis, MinIO) can be heavy on a Pi. Ensure at least 2GB RAM and swap if needed; monitor with `make ps` and `podman stats`.
- **Network**: To reach Langfuse from other machines, ensure port **3000** (and optionally **9090** for MinIO) is not bound only to `127.0.0.1` in `docker-compose.yml` if you need external access. The default compose binds web to `0.0.0.0:3000` and MinIO to `9090:9000`; internal services stay on localhost for security.

## Troubleshooting

- **“command not found: podman compose”**  
  Install the Podman Compose plugin, or install `podman-compose` so the Makefile can fall back to it (`make help` shows which command is used).

- **Permission denied (e.g. on volumes)**  
  If running rootless Podman, ensure the user has permission to create volumes in the default location, or run with `sudo make up` (not ideal long-term; prefer fixing rootless permissions).

- **Images fail to pull**  
  Run `make pull` to see errors. On Pi/arm64, if an image has no arm64 manifest, you’ll need an arm64-specific image or a build from source.

- **Containers exit or unhealthy**  
  Run `make logs` and `make ps` to see which service failed; check Postgres, ClickHouse, Redis, and MinIO health in the compose file and ensure resources (memory, disk) are sufficient.

## See also

- [Self-hosting overview](https://langfuse.com/docs/deployment/self-host) – architecture and configuration.
- [docker-compose.yml](../docker-compose.yml) – service definitions and env vars (same file used by Docker and Podman).
- [.env.prod.example](../.env.prod.example) – full list of optional and required environment variables.
