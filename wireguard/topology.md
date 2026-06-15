# WireGuard Topology

## Overview

O ambiente BobHub utiliza uma arquitetura Hub-and-Spoke.

A VPS central (HQ) atua como concentrador das conexões VPN.

---

## VPN Addressing

| Component | VPN IP       |
| --------- | ------------ |
| HQ        | 10.255.255.1 |
| Site A    | 10.255.255.2 |
| Site B    | 10.255.255.3 |

---

## Connected Networks

| Site   | Network       |
| ------ | ------------- |
| Site A | 10.10.40.0/24 |
| Site B | 10.20.40.0/24 |

---

## Topology

```text
                    HQ
              10.255.255.1
                     |
        +------------+------------+
        |                         |
        |                         |
     Site A                   Site B

VPN: 10.255.255.2       VPN: 10.255.255.3

LAN: 10.10.40.0/24      LAN: 10.20.40.0/24
```

---

## Routing

HQ conhece:

* 10.10.40.0/24
* 10.20.40.0/24

Site A conhece:

* 10.255.255.1
* 10.20.40.0/24

Site B conhece:

* 10.255.255.1
* 10.10.40.0/24
