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

### Session: 2025-08-28
- **Documentation Update**: Verified and documented current state
  - pgAdmin running with native OAuth2/Keycloak SSO
  - Auto-provisioning working for administrators group
  - External access confirmed at https://pgadmin.ai-servicers.com
  - All deployment scripts tested and functional

### Session: 2025-08-27
- **pgAdmin Keycloak SSO Integration**: Successfully implemented native OAuth2
  - Single sign-on with auto-provisioning
  - Group-based role mapping (administrators → full access)
  - Configuration in `pgadmin-oauth2-config.py`
  - Deployment script: `deploy-pgadmin-sso.sh`
  - Accessible at https://pgadmin.ai-servicers.com
- **Cleanup**: Archived obsolete deployment scripts to `archived/` directory

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
- **Networks**: postgres-net, traefik-proxy
- **External Access**: https://pgadmin.ai-servicers.com (with Keycloak SSO)
- **Local Access**: http://linuxserver.lan:8901
- **Authentication**: OAuth2/Keycloak with auto-provisioning

## Important Files & Paths
- **Deploy Scripts**: 
  - `/home/administrator/projects/postgres/deploy.sh` (PostgreSQL database server)
  - `/home/administrator/projects/postgres/deploy-pgadmin-sso.sh` (pgAdmin with Keycloak SSO)
- **Secrets**: `/home/administrator/projects/secrets/postgres.env`
- **pgAdmin Config**: 
  - `/home/administrator/projects/postgres/pgadmin-oauth2-config.py` (OAuth2 and auto-provisioning)
  - `/home/administrator/projects/secrets/postgresservers.json` (Server connections)
  - `/home/administrator/projects/secrets/.pgpass` (Database passwords)
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
- **SSO Access**: Click "Sign in with Keycloak SSO" at https://pgadmin.ai-servicers.com
- **Fallback Email**: <see secrets/postgres.env>
- **Fallback Password**: <see secrets/postgres.env>
- **Local URL**: http://linuxserver.lan:8901

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

## Keycloak OAuth2 Configuration
- **Client ID**: pgadmin
- **Client Secret**: Stored in secrets/postgres.env
- **Redirect URI**: https://pgadmin.ai-servicers.com/oauth2/callback
- **Provider**: keycloak-oidc
- **Group Restriction**: /administrators (full group path required)

### OAuth2 Proxy Network Configuration
Due to Docker container network isolation and router NAT reflection:
- **Login URL**: Uses external https://keycloak.ai-servicers.com (user-facing)
- **Token URL**: Uses internal http://keycloak:8080 (backend operations)
- **JWKS URL**: Uses internal http://keycloak:8080 (certificate verification)
- **Skip OIDC Discovery**: Required due to issuer URL mismatch

## Troubleshooting OAuth2 Issues
### "Forbidden" After Login
- **Cause**: User not in administrators group or group path incorrect
- **Solution**: Use full group path `/administrators` not just `administrators`

### Issuer Verification Error
- **Error**: "issuer did not match the issuer returned by provider"
- **Cause**: Keycloak reports external URL but proxy connects internally
- **Solution**: Set `OAUTH2_PROXY_SKIP_OIDC_DISCOVERY=true`

### Container Can't Reach Keycloak
- **Error**: "dial tcp 192.168.1.13:443: i/o timeout"
- **Cause**: Router NAT reflection prevents containers reaching external IP
- **Solution**: Use internal URLs for backend operations

## Known Issues & TODOs
- [ ] Implement automated backup schedule
- [ ] Create developer database management scripts
- [ ] Set up database creation self-service for developers
- [ ] Configure backup retention policies
- [x] pgAdmin external access with Keycloak SSO (completed 2025-08-27)
- [x] Auto-provisioning from Keycloak groups (completed 2025-08-27)

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

# Deploy pgAdmin with SSO
./deploy-pgadmin-sso.sh

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
*Last Updated: 2025-08-28 by Claude*