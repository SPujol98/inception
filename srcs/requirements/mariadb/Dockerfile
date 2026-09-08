FROM alpine:3.18

RUN apk update && apk add --no-cache mariadb mariadb-client

COPY conf/50-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY tools/mariadb.sh /usr/local/bin/mariadb.sh

RUN chmod +x /usr/local/bin/mariadb.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb.sh"]