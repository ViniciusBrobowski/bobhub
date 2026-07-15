# BobHub Infrastructure Inventory

Generated at: 2026-07-14 22:49:47

---

## Host Information

| Item | Value |
|---|---|
| Hostname | boblab.vps-kinghost.net |
| Kernel | 6.12.90+deb13.1-amd64 |
| Architecture | x86_64 |
| Operating System | Debian GNU/Linux 13 (trixie) |
| Uptime | up 3 weeks, 5 days, 22 hours, 24 minutes |

## CPU

```text
Architecture:                            x86_64
CPU(s):                                  2
On-line CPU(s) list:                     0,1
Model name:                              INTEL(R) XEON(R) SILVER 4514Y
Thread(s) per core:                      1
Core(s) per socket:                      1
Socket(s):                               2
NUMA node0 CPU(s):                       0,1
```

## Memory

```text
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       1.9Gi       333Mi       2.6Mi       1.9Gi       1.9Gi
Swap:          953Mi        12Mi       941Mi
```

## Disk Usage

```text
Filesystem      Size  Used Avail Use% Mounted on
udev            1.9G     0  1.9G   0% /dev
tmpfs           392M  1.3M  391M   1% /run
/dev/xvda3       67G   11G   54G  17% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
tmpfs           2.0G     0  2.0G   0% /tmp
/dev/xvda1      1.1G  196M  822M  20% /boot
tmpfs           1.0M     0  1.0M   0% /run/credentials/serial-getty@hvc0.service
tmpfs           392M  4.0K  392M   1% /run/user/1000
tmpfs           1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
/dev/loop0       51M   51M     0 100% /snap/snapd/27406
/dev/loop1       67M   67M     0 100% /snap/core24/1643
/dev/loop2      7.7M  7.7M     0 100% /snap/yq/2759
```

## Block Devices

```text
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0     7:0    0 50.1M  1 loop /snap/snapd/27406
loop1     7:1    0 66.8M  1 loop /snap/core24/1643
loop2     7:2    0  7.6M  1 loop /snap/yq/2759
sr0      11:0    1 1024M  0 rom  
xvda    202:0    0   70G  0 disk 
├─xvda1 202:1    0  1.1G  0 part /boot
├─xvda2 202:2    0  954M  0 part [SWAP]
└─xvda3 202:3    0   68G  0 part /
```

## Network

| Item | Value |
|---|---|
| Host IPs | 189.126.106.82 10.255.255.1 172.19.0.1 172.17.0.1 172.18.0.1 172.20.0.1 |

## Docker

| Item | Value |
|---|---|
| Docker Version | Docker version 29.6.1 build 8900f1d |
| Docker Compose Version | Docker Compose version v5.3.0 |

## Running Containers

```text
NAMES           IMAGE                       STATUS                PORTS
alertmanager    prom/alertmanager:latest    Up 7 days (healthy)   0.0.0.0:9093->9093/tcp, [::]:9093->9093/tcp
prometheus      prom/prometheus:latest      Up 7 days             0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
grafana         grafana/grafana:latest      Up 7 days             0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
node-exporter   prom/node-exporter:latest   Up 7 days             0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
```

## All Containers

```text
NAMES                 IMAGE                             STATUS                  PORTS
alertmanager          prom/alertmanager:latest          Up 7 days (healthy)     0.0.0.0:9093->9093/tcp, [::]:9093->9093/tcp
prometheus            prom/prometheus:latest            Up 7 days               0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
grafana               grafana/grafana:latest            Up 7 days               0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
node-exporter         prom/node-exporter:latest         Up 7 days               0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
nginx-proxy-manager   jc21/nginx-proxy-manager:latest   Exited (0) 7 days ago   
uptime-kuma           louislam/uptime-kuma:latest       Exited (0) 7 days ago   
portainer             portainer/portainer-ce:latest     Exited (2) 7 days ago   
```

## Docker Networks

```text
NETWORK ID     NAME                    DRIVER    SCOPE
24a0a502ac45   bridge                  bridge    local
e834c877f6c2   host                    host      local
072332e6e17e   infra_default           bridge    local
5f0ff9724d33   monitoring_default      bridge    local
b04ea9667b07   none                    null      local
78a9e1ab8116   observability_default   bridge    local
```

## Docker Volumes

```text
DRIVER    VOLUME NAME
local     infra_npm_data
local     infra_npm_letsencrypt
local     monitoring_uptime-kuma
local     observability_alertmanager-data
local     observability_grafana-data
local     observability_prometheus-data
local     portainer_data
```

## BobHub Observability Endpoints

| Service | URL | Expected Result |
|---|---|---|
| Grafana | http://localhost:3000 | Web UI |
| Prometheus | http://localhost:9090 | Health endpoint |
| Alertmanager | http://localhost:9093 | Health endpoint |
| Node Exporter | http://localhost:9100/metrics | Metrics endpoint |

## Validation Commands

```bash
curl -s http://localhost:9090/-/healthy
curl -s http://localhost:9093/-/healthy
curl -s http://localhost:9100/metrics | head
curl -s http://localhost:9090/api/v1/alertmanagers | python3 -m json.tool
```
