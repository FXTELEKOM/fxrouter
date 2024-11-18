FROM alpine:latest

RUN apk update && \
    apk add --no-cache wireguard-tools python3 py3-pip curl iptables openresolv dnsmasq iproute2 && \
    rm -rf /var/cache/apk/* 

COPY entrypoint.sh /
COPY pyinfo /pyinfo

RUN chmod +x /entrypoint.sh

RUN python3 -m venv /pyinfo/venv && \
    /pyinfo/venv/bin/pip install --no-cache-dir -r /pyinfo/req.txt

ENV PATH="/pyinfo/venv/bin:$PATH"

ENTRYPOINT ["/entrypoint.sh"]