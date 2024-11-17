# FXrouter

Az FXrouter alkalmazás lehetővé teszi bármely Linux rendszer FXtelekom routerré alakítását, így a szolgáltatás olyan eszközökön is használhatóvá válik, amelyek alapértelmezetten nem támogatják a WireGuard protokollt.

## Linux rendszer előkészítése

Az alkalmazás futtatásához Docker szükséges. A host rendszeren az alábbi függőségeket kell telepíteni:

- ip2route
- wireguard
- iptables

## Konfiguráció

Az alkalmazás saját routing és tűzfalbeállításokat hoz létre indításkor, melyek az alkalmazás leállításakor automatikusan törlődnek. A docker-compose.yml fájlban az alábbi változókat kell beállítani:

- `HOST_INTERFACE`: A host rendszer LAN hálózatra csatlakozó interfésze (pl. eth1)
- `HOST_IP`: A host rendszer belső IP címe (pl. 192.168.1.41)

A tőlünk kapott konfigurációs fájlokat a `/etc/wireguard/wg0.conf` helyre kell csatolni.

## DNS

Az FXrouter futtat egy lokális DNS szervert, amit be kell állítani azokon az eszközökön, amelyek használni fogják az alkalmazást.

## Eszköz beállítása

Az FXtelekom alkalmazást használó eszközökön a következő beállításokat kell elvégezni:

**Alapértelmezett konfiguráció példa:**
```
Default Gateway: 192.168.0.1
DNS: 192.168.0.1
```

Ha az FXroutert futtató eszköz IP címe például *192.168.0.154*, akkor az eszközön ezeket kell beállítani:
```
Default Gateway: 192.168.0.154
DNS: 192.168.0.154
```

Docker Compose:
```yml
services:
  fxrouter:
    image: fxtelekom/fxrouter
    container_name: fxrouter
    privileged: true
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
      - NET_RAW
    network_mode: host
    environment:
      - HOST_IP=192.168.0.154 
      - HOST_INTERFACE=eth1
    volumes:
      - ./wg0.conf:/etc/wireguard/wg0.conf
```
