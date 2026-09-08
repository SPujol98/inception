FROM alpine:3.18

RUN apk update && apk add --no-cache nginx openssl

# Generate self-signed SSL/TLS certificate
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=ES/ST=Barcelona/L=Barcelona/O=42/OU=42/CN=spujol-s.42.fr"

COPY conf/nginx.conf /etc/nginx/http.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]