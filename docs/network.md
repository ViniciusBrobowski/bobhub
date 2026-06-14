# Network Documentation

## Overview

O ambiente BobHub utiliza uma arquitetura Hub-and-Spoke baseada em WireGuard, onde uma VPS central (HQ) atua como concentrador das conexões VPN das filiais.

---

## HQ (Datacenter)

| Item                | Valor           |
| ------------------- | --------------- |
| Função              | Hub Central     |
| Rede VPN            | 10.255.255.0/24 |
| Endereço VPN        | 10.255.255.1    |
| Sistema Operacional | Debian          |

---

## Site A

### LAN

| Item     | Valor         |
| -------- | ------------- |
| Rede     | 10.10.40.0/24 |
| Gateway  | 10.10.40.1    |
| pfSense  | 10.10.40.1    |
| Ubuntu-A | 10.10.40.100  |

### WireGuard

| Item         | Valor        |
| ------------ | ------------ |
| Endereço VPN | 10.255.255.2 |

---

## Site B

### LAN

| Item     | Valor         |
| -------- | ------------- |
| Rede     | 10.20.40.0/24 |
| Gateway  | 10.20.40.1    |
| pfSense  | 10.20.40.1    |
| Ubuntu-B | 10.20.40.100  |

### WireGuard

| Item         | Valor        |
| ------------ | ------------ |
| Endereço VPN | 10.255.255.3 |

---

## VPN Topology

```text
                    HQ
              10.255.255.1
                     |
        +------------+------------+
        |                         |
        |                         |
   Site A                    Site B
10.10.40.0/24           10.20.40.0/24

WG: 10.255.255.2        WG: 10.255.255.3
```

---

## Future Network Planning

### HQ

```text
10.0.0.0/16
```

### Site A

```text
10.10.0.0/16
```

### Site B

```text
10.20.0.0/16
```

### VPN

```text
10.255.255.0/24
```
