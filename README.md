# wikijs-docker

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16.13--alpine3.23-336791?logo=postgresql&logoColor=white)
![Wiki.js](https://img.shields.io/badge/Wiki.js-2.5.314-1976D2)
![NGINX](https://img.shields.io/badge/NGINX-1.30.1--alpine3.23-009639?logo=nginx&logoColor=white)
![OpenLDAP](https://img.shields.io/badge/OpenLDAP-1.5.0-2E8B57)
![phpLDAPadmin](https://img.shields.io/badge/phpLDAPadmin-0.9.0-F98404)
![Prometheus](https://img.shields.io/badge/Prometheus-v3.10.0-E6522C?logo=prometheus&logoColor=white)
![Node Exporter](https://img.shields.io/badge/node--exporter-v1.11.1-555555)
![cAdvisor](https://img.shields.io/badge/cAdvisor-v0.55.1-4285F4)
![Postgres Exporter](https://img.shields.io/badge/postgres--exporter-v0.19.1-6E40C9)
![NGINX Exporter](https://img.shields.io/badge/nginx--prometheus--exporter-1.5.1-009639?logo=nginx&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-13.0.1-F46800?logo=grafana&logoColor=white)

Containerized documentation platform using Wiki.js, PostgreSQL, and NGINX. Includes HTTPS with self-signed CA, optional LDAP authentication, full observability with Prometheus and Grafana, and automated backup and restore. Deployed via Docker Compose with a single orchestration script.

---

## Architecture

### Component overview

![Component diagram](docs/img/component-diagram.png)

The stack is split into four functional layers:

1. **Proxy** — NGINX handles all inbound traffic on ports 80 and 443, terminates TLS, and routes requests to Wiki.js and Grafana. The `nginx-exporter` exposes NGINX metrics at a fixed IP (`172.22.0.10`) on the monitor network.
2. **Application** — Wiki.js serves the documentation platform. Grafana is pre-provisioned with Prometheus as datasource and dashboards loaded via bind mounts.
3. **Authentication** — OpenLDAP and phpLDAPadmin are included for LDAP integration testing. Not intended for production use.
4. **Data** — PostgreSQL handles persistence. Backup and restore scripts are included.

The monitoring layer (Prometheus, Node Exporter, cAdvisor, Postgres Exporter, NGINX Exporter) runs on a dedicated internal network and scrapes all services every 15 seconds.

### Network topology

![Network diagram](docs/img/network-diagram.png)

The host sits in a DMZ (`192.168.70.0/24`) behind a corporate router with VPN access from the LAN (`192.168.0/23`). Inside the host, Docker runs three isolated bridge networks:

- `app_network` (`172.20.0.0/24`) — connects NGINX, Wiki.js, Grafana, and the LDAP services.
- `data_network` (`172.21.0.0/24`) — internal only. Isolates PostgreSQL and LDAP from the rest of the stack.
- `monitor_network` (`172.22.0.0/24`) — internal only. Prometheus scrapes all exporters here; no external access.

---

## Deployment

**Prerequisites:** Docker and Docker Compose. If starting from scratch on Ubuntu, run `scripts/docker-install.sh` first.

**1. Clone the repository**

```bash
git clone https://github.com/jandarn/wikijs-docker.git
cd wikijs-docker
```

**2. Configure the environment**

```bash
cp .env.example .env
# Edit .env — set domain, passwords, and LOCAL_DB preference
```

**3. Make the deploy script executable and run it**

```bash
chmod +x deploy.sh
./deploy.sh
```

The script validates configuration, generates NGINX config, creates TLS certificates via `scripts/generate-certs.sh`, and brings up the full stack.

**4. Configure DNS**

Add entries for `wiki.<domain>` and `grafana.<domain>` pointing to the host IP — either in `/etc/hosts` or via your local DNS server. Direct IP access is not allowed; NGINX only responds to the configured domain names.

**5. Trust the Certificate Authority**

The self-signed CA is generated at `certs/ca.crt`. Import it into your OS or browser trust store to avoid certificate warnings.

**6. Access the stack**

```
https://wiki.<your-domain>
https://grafana.<your-domain>
```

To bring the stack down: `./deploy.sh down`

### Optional features

**Local PostgreSQL** — set `LOCAL_DB=true` in `.env` to run PostgreSQL as a container within the stack. Otherwise, point the DB variables at an external instance.

**LDAP** — set `LDAP_TEST=true` to start OpenLDAP and phpLDAPadmin. For testing only.

---

## Authors

- [@jandarn](https://github.com/jandarn)

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).
