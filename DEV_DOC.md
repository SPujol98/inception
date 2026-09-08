# Developer Documentation — Inception
 
Architecture, setup and day-to-day commands for anyone working on this project.
 
## 1. Architecture
 
Each service runs in its own Alpine 3.18 container, built from its own Dockerfile, with no shell wrappers or foreground-process hacks — everything runs as PID 1 the way it's meant to.
 
Networking is a single user-defined bridge (`srcs_inception_net`):
 
- NGINX is the only container exposed on the host, on port 443.
- NGINX talks to `wordpress:9000` over FastCGI.
- WordPress talks to `mariadb:3306`.
- Nothing else reaches the host network.
## 2. Setting up from scratch
 
**Install dependencies on the host:**
 
```bash
# Alpine
sudo apk add docker docker-cli-compose make openssl curl git
 
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y docker.io docker-compose-v2 make openssl curl git
```
 
**Create the volume paths:**
 
```bash
sudo mkdir -p /home/spujol-s/data/mariadb /home/spujol-s/data/wordpress
sudo chmod 755 /home/spujol-s/data/mariadb /home/spujol-s/data/wordpress
```
 
**Point the domain at localhost:**
 
```
127.0.0.1 spujol-s.42.fr
```
 
**Configuration and secrets:**
 
```bash
cp srcs/.env.example srcs/.env
```
 
`srcs/.env` is git-ignored — it should never be committed. Non-sensitive config (domain, ports, DB name) lives there; anything sensitive (passwords, keys) goes through Docker secrets and gets mounted at runtime instead.
 
## 3. Build and orchestration
 
```bash
make                                                          # build + start, detached
docker compose -f ./srcs/docker-compose.yml build --no-cache  # force a clean rebuild
```
 
### Directory layout
 
```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs
    ├── .env
    ├── .env.example
    ├── docker-compose.yml
    └── requirements
        ├── mariadb/
        │   ├── conf/my.cnf
        │   ├── tools/init_db.sh
        │   └── Dockerfile
        ├── nginx/
        │   ├── conf/nginx.conf
        │   └── Dockerfile
        └── wordpress/
            ├── conf/www.conf
            ├── tools/wordpress.sh
            └── Dockerfile
```
 
## 4. Useful commands
 
```bash
# Confirm port exposure — only nginx should list 443
docker port nginx
docker port wordpress
docker port mariadb
 
# Database shell
docker exec -it mariadb mariadb -u root -p
 
# WP-CLI
docker exec -it wordpress wp post list --allow-root
docker exec -it wordpress wp user list --allow-root
 
# Confirm which TLS versions the server accepts
openssl s_client -connect spujol-s.42.fr:443 -tls1_2
openssl s_client -connect spujol-s.42.fr:443 -tls1_3
```
 
## 5. Storage and persistence
 
Two named volumes back onto host directories:
 
- `db_data` → `/var/lib/mysql` in the `mariadb` container → `/home/spujol-s/data/mariadb` on the host.
- `wp_data` → `/var/www/html` in the `wordpress` container → `/home/spujol-s/data/wordpress` on the host.
Inspect where a volume actually points:
 
```bash
docker volume inspect srcs_db_data
docker volume inspect srcs_wp_data
```
 
`make down` stops the containers without touching this data. It's only wiped by `make fclean`, or manually with:
 
```bash
sudo rm -rf /home/spujol-s/data/*
```