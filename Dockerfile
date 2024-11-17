FROM alpine:latest

RUN apk update && \
    apk add --no-cache wireguard-tools curl iptables openresolv dnsmasq iproute2 && \
    rm -rf /var/cache/apk/* 

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]