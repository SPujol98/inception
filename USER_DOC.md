# User Documentation — Inception

How to run, reach and check on the Inception stack, written for anyone who just needs to use it rather than build it.

## 1. What's running

Three services work together behind a single address:

- **NGINX** — handles all incoming HTTPS traffic and is the only thing reachable from outside.
- **WordPress** — the site itself, served through PHP-FPM 8.1.
- **MariaDB** — stores everything WordPress needs: users, settings, posts.

## 2. Starting and stopping

Everything is driven from the `Makefile` at the repository root.

```bash
make          # build and start all services
make down     # stop services, data is kept
make down && make up   # restart
```

## 3. Accessing the site

**Public site:** `https://spujol-s.42.fr`

The certificate is self-signed, so the browser will warn you the first time — click through "Advanced" → "Proceed" to continue.

**WordPress admin panel:** `https://spujol-s.42.fr/wp-login.php`

## 4. Credentials

All credentials live in `srcs/.env`. If you're setting this up for the first time, copy the template and fill it in:

```bash
cp srcs/.env.example srcs/.env
```

What's in there:

- `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` — the WordPress administrator (the username deliberately avoids "admin" for security reasons).
- `WP_USER` / `WP_USER_PASSWORD` — a regular author account for posts and comments.
- `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` — the database WordPress connects to.
- `MYSQL_ROOT_PASSWORD` — MariaDB's admin password.

## 5. Checking everything is healthy

**Container status:**

```bash
make ps
```

`nginx`, `wordpress` and `mariadb` should all show as `Up`.

**Logs, if something looks wrong:**

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**A quick HTTPS check from the terminal:**

```bash
curl -kIL https://spujol-s.42.fr
```

A healthy response starts with `HTTP/1.1 200 OK` (or `HTTP/2 200`).