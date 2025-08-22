# Claude AI Assistant Notes - PostgreSQL

> **For overall environment context, see: `/home/administrator/projects/AINotes/AINotes.md`**

## Project Overview
PostgreSQL is the primary database server for the infrastructure, providing:
- Central database service for multiple applications
- Database isolation between projects
- pgAdmin web interface for database management
- Automated backup capabilities

## Recent Work & Changes
_This section is updated by Claude during each session_

### Session: 2025-08-22
- **MIGRATION COMPLETE**: Moved from websurfinmurf to administrator ownership
- Deployed pgAdmin for web-based database management
- Created pgAdmin configuration files (postgresservers.json, .pgpass)
- Updated all scripts to use administrator paths
- Configured proper network isolation on `postgres-net`
- Successfully managing both main postgres and keycloak-postgres databases

### Session: 2025-08-17
- Initial CLAUDE.md created

## Network Architecture
- **Network**: `postgres-net` only
- **Connected Services**: pgAdmin, keycloak-postgres, and applications needing DB access
- **Isolation**: Not accessible via traefik-proxy for security
- **Port**: 5432 exposed on host for local access

## Container Configuration
### Main PostgreSQL
- **Container**: postgres
- **Image**: postgres:15
- **Volume**: postgres_data (Docker volume)
- **Network**: postgres-net only

### pgAdmin
- **Container**: pgadmin
- **Image**: dpage/pgadmin4
- **Port**: 8901 (web interface)
- **Network**: postgres-net only
- **Access**: http://linuxserver.lan:8901

## Important Files & Paths
- **Deploy Scripts**: 
  - `/home/administrator/projects/postgres/deploy.sh` (PostgreSQL)
  - `/home/administrator/projects/postgres/deployui.sh` (pgAdmin)
- **Secrets**: `/home/administrator/projects/secrets/postgres.env`
- **pgAdmin Config**: 
  - `/home/administrator/projects/secrets/postgresservers.json`
  - `/home/administrator/projects/secrets/.pgpass`
- **Backup Scripts**:
  - `backupdb.sh` - Full database backup
  - `backupdbsql.sh` - SQL format backup
  - `restoredb.sh` - Restore from backup

## Credentials
### Main PostgreSQL
- **Admin User**: admin
- **Admin Password**: <see secrets/postgres.env>
- **Default Database**: defaultdb
- **Port**: 5432

### pgAdmin
- **Email**: <see secrets/postgres.env>
- **Password**: <see secrets/postgres.env>
- **URL**: http://linuxserver.lan:8901

### Keycloak Database (managed separately)
- **Container**: keycloak-postgres
- **Database**: keycloak
- **User**: keycloak
- **Password**: <see secrets/keycloak.env>

## Database Management
### Current Databases
1. **defaultdb** - Default database
2. **postgres** - System database
3. **keycloak** - Keycloak identity management (in keycloak-postgres container)

### pgAdmin Server Connections
Add these servers in pgAdmin:
1. **Main PostgreSQL**
   - Host: postgres
   - Port: 5432
   - Username: admin
   - Password: <see secrets/postgres.env>

2. **Keycloak PostgreSQL**
   - Host: keycloak-postgres
   - Port: 5432
   - Username: keycloak
   - Password: <see secrets/keycloak.env>

## Known Issues & TODOs
- [ ] Implement automated backup schedule
- [ ] Create developer database management scripts
- [ ] Set up database creation self-service for developers
- [ ] Configure backup retention policies

## Important Notes
- **Owner**: administrator (UID 2000)
- **File ownership**: administrator:administrators
- **Network**: Isolated on postgres-net for security
- **Backup Location**: Configured via POSTGRES_BACKUP_DIR environment variable

## Common Commands
```bash
# Deploy PostgreSQL
cd /home/administrator/projects/postgres
./deploy.sh

# Deploy pgAdmin
./deployui.sh

# Check PostgreSQL logs
docker logs postgres --tail 50

# Connect via psql
psql -h localhost -p 5432 -U admin -d defaultdb
# Password: <see secrets/postgres.env>

# List all databases
psql -h localhost -p 5432 -U admin -d postgres -c "\l"

# Backup database
./backupdb.sh [database_name]

# Restore database
./restoredb.sh database_name backup_file.tar.gz

# Check container networks
docker inspect postgres --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}'
```

## Future Development Plans
1. **Developer Self-Service** (planned):
   - Script for developers to request new databases
   - Automated provisioning with proper isolation
   - Individual database credentials per project

2. **Backup Automation**:
   - Scheduled backups via cron
   - Auto-discovery of all databases
   - Retention policy implementation

3. **Monitoring**:
   - Database size tracking
   - Connection monitoring
   - Performance metrics

## Backup Considerations
- **Critical**: postgres_data Docker volume
- **Important**: Environment files and configuration
- **Scripts**: Backup and restore scripts in project directory
- **Location**: Defined by POSTGRES_BACKUP_DIR in postgres.env

---
*Last Updated: 2025-08-22 by Claude*