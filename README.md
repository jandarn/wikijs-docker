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

Containerized documentation platform using Wiki.js, PostgreSQL, and NGINX. Includes HTTPS, LDAP authentication, monitoring with Prometheus and Grafana, and automated backups. Designed for secure, scalable deployment and reproducibility using Docker Compose.


## Installation
1. **Clone the repository**
```bash
git clone https://github.com/jandarn/wikijs-docker
cd wikijs-docker
```
2. **Make deploy.sh executable**
```bash
chmod +x deploy.sh
```
3. **Run the deployment script**
```
./deploy.sh
```
4. **Configure environment variables:** Once you run the *deploy.sh* script for the first time, the *.env.example* will be copied to a definitive configuration file ***.env***.

The deployment script won't work if:
```
.env == .env.example
```

5. **Run the deployment script again**
```
./deploy.sh
```
If this message appears:
```
Error: Docker is not installed. Please install Docker and try again.
```
You will need to install Docker and Docker-Compose to run the containers. You can do it via the installation script in Ubuntu:
```
sudo bash wikijs-docker/scripts/docker-install.sh 
```
Or, if you are running the infrastructure in other distribution/OS, please check the official installation docs:
- [Docker Installation Docs](https://docs.docker.com/engine/install/)
- [Docker Compose Plugin Installation Docs](https://docs.docker.com/compose/install)



6. Once you have Docker and Docker Compose installed, **run again the deployment script**:
```
deploy.sh
```
This script will:
- Validate configuration files
- Generate required configs
- Create SSL certificates (self-signed CA) for HTTPS with NGINX
- Run all the containers.

If you want to stop the orchestration: `deploy.sh down`

### Final Steps
#### 🌐 DNS Configuration

To access services, the client must resolve:
```
wiki.<your-domain>
grafana.<your-domain>
```

Both must point to the server IP. Options:

- Edit */etc/hosts*
- Or configure your *local DNS server*

⚠️ *Access via IP is not allowed, only via domain names.*

#### 🔐 Trust the Certificate Authority (CA)
A self-signed CA is generated automatically at ***wikijs-docker/certs/ca.crt***. 

You must add it to your system/browser trusted store.

Options:
- Add to OS trusted root CA
- Or import it manually in each browser/device

⚠️ *Otherwise, HTTPS warnings will appear*

### Accessing the Services
Once you have configured the new DNS entries and added the **ca.crt** to your trusted source. You will be able to access correctly:
```
- https://wiki.<yourdomain>
- https://grafana.<yourdomain>
```
### Additional Features
#### Local DB: PostgreSQL
If you want to host the data of the Wiki server directly in another container, set `LOCAL_DB` to `true` in your `.env` folder. Then target the container on the database configuration:
```
LOCAL_DB=true
DB_HOST=psql
DB_PORT=5432
DB_TYPE=postgres
DB_USER=wikijs
DB_PASS=change_me
DB_NAME=wikijs
```
#### LDAP server
This system aims to be suited for corporative environments. Therefore, an LDAP authentication test is provided to check how domain users can access the different services.

However, is important to understand this is a **testing feature**, and is not suited for production use.
```
LDAP_TEST=true
LDAP_BASE_DN=dc=netsupport,dc=dom
LDAP_ADMIN_PASSWORD=change_me
```
## Authors

- [@onyxdream](https://www.github.com/jandarn)

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).

You are free to:
- Use
- Modify
- Distribute

Under the condition that:
- Any derivative work must also be licensed under GPL-3.0
- Source code must be made available
