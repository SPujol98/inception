# Inception

A small web infrastructure built from scratch with Docker Compose inside an Alpine Linux VM — NGINX, WordPress and MariaDB, each in its own container built from a custom Dockerfile (Alpine 3.18, no pre-built images).

![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![Base image](<https://img.shields.io/badge/Base-Alpine%203.18-orange>)
![NGINX](<https://img.shields.io/badge/NGINX-TLS%201.2%2F1.3-brightgreen>)
![Stack](<https://img.shields.io/badge/Stack-WordPress%20%2B%20MariaDB-yellow>)

---

## Infrastructure

```
            https://spujol-s.42.fr  (browser)
                        │  TLS 1.2 / 1.3 only — port 443
                        ▼
        ┌─────────────────────────────────┐
        │  NGINX                          │
        │  static files + FastCGI pass    │
        └───────────────┬─────────────────┘
                        │ FastCGI :9000
                        ▼
        ┌─────────────────────────────────┐
        │  WordPress + PHP-FPM            │
        │  WP-CLI idempotent bootstrap    │
        └───────────────┬─────────────────┘
                        │ MySQL :3306
                        ▼
        ┌─────────────────────────────────┐
        │  MariaDB                        │
        └─────────────────────────────────┘

   wp_data ───► nginx + wordpress        db_data ───► mariadb
   (named volumes bound to /home/<user>/data/ on the host)

   ── all three on the `inception_net` bridge · only 443 exposed ──
```

The only entry point is NGINX on port 443 with TLSv1.2/TLSv1.3. WordPress talks to the database over the internal bridge network (`inception_net`), and MariaDB is never reachable from outside it. Every container is built from its own Dockerfile — no `pull`, no `network: host`, no `--link`, no `tail -f` / `sleep infinity` hacks to keep things alive.

---

## Design choices

**Virtual machines vs Docker**
A VM virtualizes hardware through a hypervisor: every VM boots its own kernel and needs a fixed slice of CPU, RAM and disk, so startup is slow and overhead is high. Docker instead virtualizes at the OS level, sharing the host kernel and using namespaces (PID, NET, MNT, IPC, UTS) plus cgroups to isolate and cap what each container can see and use. The result is containers that start almost instantly and cost far less in resources.

**Secrets vs environment variables**
`.env` is fine for configuration that isn't sensitive — domain name, DB name, port numbers — but anything stored there can still be read via `docker inspect` or `/proc/<PID>/environ`. Docker secrets solve that: sensitive values (passwords, keys) are mounted as memory-backed files under `/run/secrets/` at runtime instead, so they never end up in image layers, command history, or the process table.

**Docker network vs host network**
A custom bridge network keeps containers isolated from the host's interfaces and lets them find each other by service name through Docker's internal DNS (`mariadb`, `wordpress`, …). `network: host` throws that isolation away — containers sit directly on the host's network stack, port mapping becomes meaningless, and the whole point of separating services is lost.

**Docker volumes vs bind mounts**
Volumes are managed by Docker itself, inside Docker's own storage area, which keeps permissions and the host filesystem layout out of the equation. Bind mounts map a specific host path straight into the container. This project uses named volumes configured to persist to `/home/<login>/data/`, which keeps the Docker volume lifecycle while still guaranteeing where the data physically lives.

---

## WordPress bootstrap

`wordpress.sh` runs once per container start and is fully idempotent:

1. **Refuses weak admin names** — if `WP_ADMIN_USER` contains `admin` or `administrator`, the script exits with an error.
2. **Waits for MariaDB** — probes the database with a 120s timeout instead of racing it at startup.
3. **Downloads core once** — `wp core download` and `wp config create` only run if `wp-config.php` doesn't exist yet.
4. **Installs conditionally** — site and users are only created if WordPress isn't already installed, so restarts never duplicate data.

---

## Getting started

### Prerequisites

- Docker, Docker Compose and Make installed.
- Local DNS pointing the domain to your machine:
  ```bash
  sudo sed -i '1s/^/127.0.0.1 spujol-s.42.fr\n/' /etc/hosts
  ```
- Persistent storage directories created on the host:
  ```bash
  sudo mkdir -p /home/<login>/data/mariadb /home/<login>/data/wordpress
  ```

### Setup

```bash
git clone <repository_url> inception && cd inception
cp srcs/.env.example srcs/.env   # then edit with your own values
make
```

Once the containers are up, visit **https://spujol-s.42.fr** and accept the self-signed certificate.

### Makefile targets

| Target                  | Effect                                                                      |
| ----------------------- | --------------------------------------------------------------------------- |
| `make` / `make all` | Prepares host directories, builds images, starts everything                 |
| `make up`             | Starts already-built containers                                             |
| `make down`           | Stops containers and removes the network                                    |
| `make ps`             | Shows container status                                                      |
| `make logs`           | Follows logs from all services                                              |
| `make clean`          | Stops containers and removes the images                                     |
| `make fclean`         | Full purge: containers, images, network, volumes and`/home/<login>/data/` |
| `make re`             | `fclean` followed by `all`                                              |

---

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [NGINX core documentation](https://nginx.org/en/docs/)
- [WordPress WP-CLI documentation](https://developer.wordpress.org/cli/commands/)
- [OpenSSL command-line reference](https://www.openssl.org/docs/man3.0/man1/)

### AI usage disclosure

AI assistance was used at a few specific points during this project:

- Debugging a PHP memory limit issue that was interrupting a WP-CLI extraction step on Alpine (fixed by raising the limit in a custom `php.ini`).
- Checking the exact `openssl` flags needed to test which TLS versions the server would negotiate.
- A pass over the documentation structure against the evaluation rubric.
