#!/bin/bash
BANNER=$(cat <<EOF
  ________   _________ ______ _      ______ _  ______  __  __
 |  ____\ \ / /__   __|  ____| |    |  ____| |/ / __ \|  \/  |
 | |__   \ V /   | |  | |__  | |    | |__  | ' / |  | | \  / |
 |  __|   > <    | |  |  __| | |    |  __| |  <| |  | | |\/| |
 | |     / . \   | |  | |____| |____| |____| . \ |__| | |  | |
 |_|    /_/ \_\  |_|  |______|______|______|_|\_\____/|_|  |_|
                     FXRouter Alpha 0.0.1

EOF
)

color_text() {
    local text=$1
    local color=$2

    RED_FULL="\e[101m"
    RED_TEXT="\e[31m"
    BLUE_TEXT="\e[36m"
    YELLOW_TEXT="\e[93m"
    GREEN_TEXT="\e[92m"
    RESET_TEXT="\e[0m"
    MAGENTA_TEXT="\e[35m"

    case $color in
        "RED_FULL") color_code=$RED_FULL ;;
        "RED_TEXT") color_code=$RED_TEXT ;;
        "YELLOW_TEXT") color_code=$YELLOW_TEXT ;;
        "GREEN_TEXT") color_code=$GREEN_TEXT ;;
        "MAGENTA_TEXT") color_code=$MAGENTA_TEXT ;;
        "BLUE_TEXT") color_code=$BLUE_TEXT ;;
        *) color_code=$RESET_TEXT ;;
    esac

    echo -e "${color_code}${text}${RESET_TEXT}"
}

echo -e "$BANNER\n"

if [ ! -f /etc/wireguard/wg0.conf ]; then
    color_text "Wireguard Konfiguráció nem található!" "RED_TEXT"
    color_text "Biztos felmountoltad a docker containerre?" "RED_TEXT"

    exit 1
fi

exit_cleanup() {
    echo -e "\n"
    color_text "Routing beállítások visszaállítása" "BLUE_TEXT"

    delete_route_ip_from_url_list "https://fxtelekom.org/ips/cloudflare.txt"
    delete_route_ip_from_url_list "https://fxtelekom.org/ips/gcore.txt"
    delete_route_ip_from_url_list "https://fxtelekom.org/ips/hunt.txt"
    delete_route_ip_from_url_list "https://fxtelekom.org/ips/valve-cs2.txt"
    delete_route_ip_from_url_list "https://fxtelekom.org/ips/websupportsk.txt"

    ip route del default dev wg0 table 51820
    iptables -t nat -D POSTROUTING -o wg0 -j MASQUERADE


    iptables -t nat -D POSTROUTING -o $HOST_INTERFACE -j MASQUERADE
    iptables -D FORWARD -i $HOST_INTERFACE -o $HOST_INTERFACE -j ACCEPT

    color_text "Routing beállítások visszaállítva!" "GREEN_TEXT"
    color_text "Tűzfalbeállítások visszaállítása" "BLUE_TEXT"

    iptables -D DOCKER-USER -i $HOST_INTERFACE -o wg0 -j ACCEPT
    iptables -D DOCKER-USER -i wg0 -o $HOST_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

    color_text "Tűzfalbeállítások visszaállítva" "GREEN_TEXT"
    color_text "Wireguard szolgáltatás leállítása" "BLUE_TEXT"

    wg-quick down wg0 2> /dev/nulll

    color_text "Wireguard szolgáltatás leállítva" "GREEN_TEXT"

    echo -e "\n"
    color_text "Minden beállítás visszaállítva!" "MAGENTA_TEXT"

    exit 0
}

trap 'exit_cleanup' SIGTERM SIGINT SIGQUIT

route_ip_from_url_list() {
    url=$1

    ip_list=$(curl -s $url | grep -v '^\s*#' | grep -v '^\s*$')

    while IFS= read -r ip; do
        if [[ -n "$ip" ]]; then
            if [[ "$ip" =~ : ]]; then
                color_text "$ip cím hozzáadva a routing listához (IPv6)" "BLUE_TEXT"
                ip -6 rule add to $ip lookup 51820
            else
                color_text "$ip cím hozzáadva a routing listához (IPv4)" "BLUE_TEXT"
                ip rule add to $ip lookup 51820
            fi
        fi
    done <<< "$ip_list"
}

delete_route_ip_from_url_list() {
    url=$1

    ip_list=$(curl -s $url | grep -v '^\s*#' | grep -v '^\s*$')

    while IFS= read -r ip; do
        if [[ -n "$ip" ]]; then
            if [[ "$ip" =~ : ]]; then
                color_text "$ip cím eltávolítva a routing listából (IPv6)" "BLUE_TEXT"

                ip -6 rule del to $ip lookup 51820

            else

                color_text "$ip cím eltávolítva a routing listából (IPv6)" "BLUE_TEXT"

                ip rule del to $ip lookup 51820

            fi
        fi
    done <<< "$ip_list"
}

color_text "DNSMASQ konfigurálása" "BLUE_TEXT"


function append_dns_servers() {
    local url="https://fxtelekom.org/ips/dns.txt"
    ips=$(curl -s "$url" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

    for ip in $ips; do
        color_text "DNS szerver hozzáadva a DNSMASQ-hoz: $ip" "BLUE_TEXT"
        echo "server=$ip" >> "$DNSMASQ_CONFIG"
    done
}

DNSMASQ_CONFIG="/etc/dnsmasq.conf"

echo "bind-interfaces" > $DNSMASQ_CONFIG
echo "interface=$HOST_INTERFACE" >> $DNSMASQ_CONFIG
echo "listen-address=$HOST_IP" >> $DNSMASQ_CONFIG
echo "no-hosts" >> $DNSMASQ_CONFIG
echo "cache-size=1000" >> $DNSMASQ_CONFIG
echo "neg-ttl=60" >> $DNSMASQ_CONFIG

append_dns_servers

echo "stop-dns-rebind" >> $DNSMASQ_CONFIG
echo "rebind-localhost-ok" >> $DNSMASQ_CONFIG
echo "bogus-priv" >> $DNSMASQ_CONFIG
echo "no-resolv" >> $DNSMASQ_CONFIG

color_text "DNSMASQ konfiguráció létrehozva" "GREEN_TEXT"

color_text "DNSMASQ szolgáltatás elindítása" "BLUE_TEXT"

dnsmasq --keep-in-foreground &

DNSMASQ_PID=$!

sleep 1

if ! pgrep -f "dnsmasq" > /dev/null; then

  color_text "A DNSMASQ szolgáltatás nem tudott elindulni!" "RED_TEXT"

  exit 1

else
  color_text "DNSMASQ szolgáltatás elindítva" "GREEN_TEXT"
fi

color_text "Wireguard szolgáltatás elindítása" "BLUE_TEXT"

wg-quick up wg0 2> /dev/null

color_text "Wireguard elindítva!" "GREEN_TEXT"

color_text "Routing beállítások létrehozása" "BLUE_TEXT"

route_ip_from_url_list "https://fxtelekom.org/ips/cloudflare.txt"
route_ip_from_url_list "https://fxtelekom.org/ips/gcore.txt"
route_ip_from_url_list "https://fxtelekom.org/ips/hunt.txt"
route_ip_from_url_list "https://fxtelekom.org/ips/valve-cs2.txt"
route_ip_from_url_list "https://fxtelekom.org/ips/websupportsk.txt"


ip route add default dev wg0 table 51820
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE

iptables -t nat -I POSTROUTING -o $HOST_INTERFACE -j MASQUERADE
iptables -I FORWARD -i $HOST_INTERFACE -o $HOST_INTERFACE -j ACCEPT

color_text "Routing beállítások létrehozva!" "GREEN_TEXT"

color_text "Tűzfalbeállítások létrehozása" "BLUE_TEXT"

iptables -I DOCKER-USER -i $HOST_INTERFACE -o wg0 -j ACCEPT
iptables -I DOCKER-USER -i wg0 -o $HOST_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

color_text "Tűzfalbeállítások létrehozva!" "GREEN_TEXT"

echo -e "\n"
color_text "Minden beállítás sikeresen megtörtént!" "GREEN_TEXT"

while true; do
    sleep 1
done