# WireGuard Documentation

Documentação da arquitetura VPN do BobHub.

A comunicação entre os sites é realizada através de uma topologia Hub-and-Spoke utilizando WireGuard.

## Components

* HQ (Hub)
* Site A (Spoke)
* Site B (Spoke)

## VPN Network

```text
10.255.255.0/24
```

## Documentation

* topology.md
* hq.conf.example
* site-a.conf.example
* site-b.conf.example
