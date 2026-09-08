*This project has been created as part of the 42 curriculum by spujol-s.*

## Description

Inception is a system administration project that consists of building a small, containerized web infrastructure from scratch using Docker and Docker Compose, all running inside an Alpine Linux virtual machine.

The stack is split into three independent services, each in its own container built from a custom Dockerfile (Alpine 3.18, no pre-built images):

- **NGINX** — the only entry point to the infrastructure, listening on port 443 with TLSv1.2/TLSv1.3 only.
- **WordPress + PHP-FPM** — the application layer, listening on port 9000, talking to the database over the internal network.
- **MariaDB** — the database, on port 3306, never exposed outside the Docker network.

Everything communicates over a dedicated bridge network (`srcs_inception_net`), and no container relies on shortcuts such as `network: host`, `--link`, or infinite-loop hacks (`tail -f`, `sleep infinity`, etc.) to stay alive.

## Project design choices

**Virtual Machines vs Docker**
A VM virtualizes hardware through a hypervisor: every VM boots its own kernel and needs a fixed slice of CPU, RAM and disk, so startup is slow and overhead is high. Docker instead virtualizes at the OS level, sharing the host kernel and using namespaces (PID, NET, MNT, IPC, UTS) plus cgroups to isolate and cap what each container can see and use. The result is containers that start almost instantly and cost far less in resources.

**Secrets vs environment variables**
`.env` is fine for configuration that isn't sensitive — domain name, DB name, port numbers — but anything stored there can still be read via `docker inspect` or `/proc/<PID>/environ`. Docker secrets solve that: sensitive values (passwords, keys) are mounted as memory-backed files under `/run/secrets/` at runtime instead, so they never end up in image layers, command history, or the process table.

**Docker network vs host network**
A custom bridge network keeps containers isolated from the host's interfaces and lets them find each other by service name through Docker's internal DNS (`mariadb`, `wordpress`, …). `network: host` throws that isolation away — containers sit directly on the host's network stack, port mapping becomes meaningless, and the whole point of separating services is lost.

**Docker volumes vs bind mounts**
Volumes are managed by Docker itself, inside Docker's own storage area, which keeps permissions and the host filesystem layout out of the equation. Bind mounts map a specific host path straight into the container. This project uses named volumes configured to persist to `/home/spujol-s/data/`, which keeps the Docker volume lifecycle while still guaranteeing where the data physically lives.

## Instructions

### Prerequisites

- Docker, Docker Compose and Make installed.
- Local DNS pointing the domain to your machine:
  ```bash
  sudo sed -i '1s/^/127.0.0.1 spujol-s.42.fr\n/' /etc/hosts
  ```
- Persistent storage directories created on the host:
  ```bash
  sudo mkdir -p /home/spujol-s/data/mariadb /home/spujol-s/data/wordpress
  ```

### Setup

```bash
git clone <repository_url> inception && cd inception
cp srcs/.env.example srcs/.env   # then edit with your own values
make
```

Once the containers are up, visit **https://spujol-s.42.fr** and accept the self-signed certificate.

### Makefile targets

| Target | Effect |
|---|---|
| `make` / `make all` | Prepares host directories, builds images, starts everything |
| `make up` | Starts already-built containers |
| `make down` | Stops containers and removes the network |
| `make ps` | Shows container status |
| `make logs` | Follows logs from all services |
| `make clean` | Stops containers and removes the images |
| `make fclean` | Full purge: containers, images, network, volumes and `/home/spujol-s/data/` |
| `make re` | `fclean` followed by `all` |

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
- A pass over the documentation structure against the 42 evaluation rubric.