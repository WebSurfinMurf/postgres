# Claude AI Assistant Notes - PostgreSQL

> **For overall environment context, see: `/home/administrator/projects/AINotes/SYSTEM-OVERVIEW.md`**  
> **Network details: `/home/administrator/projects/AINotes/network.md`**  
> **Security configuration: `/home/administrator/projects/AINotes/security.md`**

## Project Overview
PostgreSQL is the primary database server for the infrastructure, providing:
- Central database service for multiple applications (10+ databases)
- Database isolation between projects with dedicated users
- pgAdmin web interface with Keycloak SSO for database management
- Automated backup capabilities
- Port 5432 exposed for direct database connections
- Two PostgreSQL instances (main + keycloak-dedicated)

## Current State (2025-09-05)
- **Main PostgreSQL**: Running on port 5432 (12+ days uptime)
- **Keycloak PostgreSQL**: Dedicated instance for authentication (13+ days uptime)
- **pgAdmin**: Web interface with SSO at https://pgadmin.ai-servicers.com
- **MCP PostgreSQL**: Running for Claude Code database operations
- **Databases**: 9 active databases serving various applications (infisical_db removed)

## Recent Work & Changes
_This section is updated by Claude during each session_

### Session: 2025-09-05
- **Documentation Update**: Comprehensive update with current state
  - Verified 10 active databases in production
  - Confirmed network topology (postgres-net + guacamole-net)
  - Updated database inventory with all active services
  - Documented TimescaleDB relationship (separate instance on port 5433)
- **Database Cleanup**: Removed unused infisical_db
  - Dropped database infisical_db (16MB freed)
  - Dropped user infisical
  - No active connections found before removal

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
- **Primary Network**: `postgres-net` (172.27.0.0/16)
- **Secondary Network**: `guacamole-net` (for Guacamole database access)
- **Connected Services**: 
  - pgAdmin (web management)
  - keycloak-postgres (authentication DB)
  - Nextcloud, OpenProject, Guacamole (application databases)
  - MCP servers (database operations)
  - Postfix/Mail services
- **Isolation**: Not accessible via traefik-proxy for security
- **Port**: 5432 exposed on host for direct database access

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
### Current Databases (Main PostgreSQL Instance)
1. **defaultdb** - Default database for general use
2. **postgres** - System database (PostgreSQL internals)
3. **guacamole_db** - Apache Guacamole remote desktop gateway
4. **mcp_memory** - MCP memory storage (original)
5. **mcp_memory_admin** - MCP memory for admin user (legacy)
6. **mcp_memory_administrator** - MCP memory for administrator user (active)
7. **nextcloud** - Nextcloud file sync and collaboration
8. **openproject_production** - OpenProject project management
9. **postfixadmin** - Mail server administration interface

### Keycloak Database (Separate Instance)
- **Container**: keycloak-postgres
- **Database**: keycloak - Identity and access management
- **Port**: 5432 (internal only)
- **Network**: postgres-net

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
- [ ] Implement automated backup schedule with cron
- [ ] Create developer database management scripts
- [ ] Set up database creation self-service for developers
- [ ] Configure backup retention policies (30 days suggested)
- [ ] Migrate legacy MCP memory databases to single instance
- [ ] Document database user permissions and access patterns
- [ ] Set up monitoring for database performance metrics
- [x] pgAdmin external access with Keycloak SSO (completed 2025-08-27)
- [x] Auto-provisioning from Keycloak groups (completed 2025-08-27)
- [x] Multiple database instances for service isolation (completed)

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

# Connect via psql (with password)
PGPASSWORD='Pass123qp' psql -h localhost -p 5432 -U admin -d defaultdb

# Alternative: Connect to specific host
PGPASSWORD='Pass123qp' psql -h linuxserver.lan -p 5432 -U admin -d postgres

# List all databases
PGPASSWORD='Pass123qp' psql -h localhost -p 5432 -U admin -d postgres -c "\l"

# Check database sizes
PGPASSWORD='Pass123qp' psql -h localhost -p 5432 -U admin -d postgres -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size FROM pg_database ORDER BY pg_database_size(pg_database.datname) DESC;"

# Backup database
./backupdb.sh [database_name]

# Restore database
./restoredb.sh database_name backup_file.tar.gz

# Check container networks
docker inspect postgres --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}'

# View active connections
PGPASSWORD='Pass123qp' psql -h localhost -p 5432 -U admin -d postgres -c "SELECT datname, usename, application_name, client_addr, state FROM pg_stat_activity WHERE state = 'active';"
```

## Guidelines for New Applications

### How to Connect a New Application to PostgreSQL

#### Step 1: Create Database and User
```bash
# Connect as admin to create new database
PGPASSWORD='Pass123qp' psql -h localhost -p 5432 -U admin -d postgres

# In PostgreSQL prompt, create user and database:
CREATE USER myapp_user WITH PASSWORD 'SecurePassword123!';
CREATE DATABASE myapp_db OWNER myapp_user;
GRANT ALL PRIVILEGES ON DATABASE myapp_db TO myapp_user;

# For applications needing extensions:
\c myapp_db
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- For text search
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- For advanced indexing
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- For UUID generation
\q
```

#### Step 2: Network Configuration

**For Docker Containers:**
```bash
# Add container to postgres-net network
docker run -d \
  --name myapp \
  --network postgres-net \
  -e DATABASE_URL="postgresql://myapp_user:SecurePassword123!@postgres:5432/myapp_db" \
  myapp:latest

# Or if container needs multiple networks:
docker run -d \
  --name myapp \
  --network traefik-proxy \
  myapp:latest

# Then connect to postgres-net:
docker network connect postgres-net myapp
```

#### Step 3: Connection Strings

**Internal Docker Connection (Recommended):**
```bash
# Using Docker hostname (container-to-container)
postgresql://myapp_user:password@postgres:5432/myapp_db

# Environment variable format
DATABASE_URL=postgresql://myapp_user:password@postgres:5432/myapp_db
```

**External/Development Connection:**
```bash
# From host machine or external service
postgresql://myapp_user:password@linuxserver.lan:5432/myapp_db

# Or using localhost
postgresql://myapp_user:password@localhost:5432/myapp_db
```

#### Step 4: Environment File Setup
Create `/home/administrator/secrets/myapp.env`:
```bash
# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=myapp_db
DB_USER=myapp_user
DB_PASSWORD=SecurePassword123!
DATABASE_URL=postgresql://myapp_user:SecurePassword123!@postgres:5432/myapp_db

# Alternative format for some applications
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=myapp_db
POSTGRES_USER=myapp_user
POSTGRES_PASSWORD=SecurePassword123!
```

#### Step 5: Application Examples

**Node.js Application:**
```javascript
// Using DATABASE_URL
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false
});

// Or using individual variables
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
});
```

**Python/Django:**
```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'postgres'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

**Ruby on Rails:**
```yaml
# database.yml
production:
  adapter: postgresql
  encoding: unicode
  host: <%= ENV['DB_HOST'] || 'postgres' %>
  port: <%= ENV['DB_PORT'] || 5432 %>
  database: <%= ENV['DB_NAME'] %>
  username: <%= ENV['DB_USER'] %>
  password: <%= ENV['DB_PASSWORD'] %>
  pool: 10
```

#### Step 6: Verify Connection
```bash
# Test from application container
docker exec myapp pg_isready -h postgres -p 5432 -U myapp_user -d myapp_db

# Test with psql
docker exec myapp psql postgresql://myapp_user:password@postgres:5432/myapp_db -c "SELECT 1;"

# Check active connections
PGPASSWORD='Pass123qp' psql -h localhost -p 5432 -U admin -d postgres -c \
  "SELECT datname, usename, application_name, state FROM pg_stat_activity WHERE datname = 'myapp_db';"
```

### Best Practices for New Applications

#### 1. User & Permission Management
- **One user per application** - Never share database users between apps
- **Least privilege** - Grant only necessary permissions
- **No superuser** - Applications should never use admin/superuser accounts
- **Password complexity** - Use strong, unique passwords for each user

#### 2. Database Naming Convention
```
Application: myapp
Database name: myapp_db or myapp_production
User name: myapp_user or myapp
Test database: myapp_test
Development: myapp_dev
```

#### 3. Connection Pooling
- Set appropriate pool size (typically 10-20 connections)
- Use PgBouncer for applications needing many connections
- Monitor connection usage to avoid exhaustion

#### 4. Security Checklist
- [ ] Database user has minimal required permissions
- [ ] Password stored in environment file, not code
- [ ] Environment file has 600 permissions
- [ ] Connection uses internal Docker network when possible
- [ ] SSL enabled for external connections (future)
- [ ] Regular password rotation schedule

#### 5. Monitoring Setup
```bash
# Add to monitoring queries
# Check database size
SELECT pg_database.datname, 
       pg_size_pretty(pg_database_size(pg_database.datname)) AS size 
FROM pg_database 
WHERE datname = 'myapp_db';

# Monitor connections
SELECT count(*) as connections 
FROM pg_stat_activity 
WHERE datname = 'myapp_db';

# Check for long-running queries
SELECT pid, age(clock_timestamp(), query_start), usename, query 
FROM pg_stat_activity 
WHERE datname = 'myapp_db' 
AND state != 'idle' 
AND query NOT ILIKE '%pg_stat_activity%' 
ORDER BY query_start;
```

### Quick Setup Script Template
```bash
#!/bin/bash
# create-app-database.sh

APP_NAME="myapp"
DB_NAME="${APP_NAME}_db"
DB_USER="${APP_NAME}_user"
DB_PASSWORD=$(openssl rand -base64 32)

# Create database and user
PGPASSWORD='Pass123qp' psql -h localhost -p 5432 -U admin -d postgres << EOF
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
\c ${DB_NAME}
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOF

# Create environment file
cat > /home/administrator/secrets/${APP_NAME}.env << EOF
DB_HOST=postgres
DB_PORT=5432
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
EOF

chmod 600 /home/administrator/secrets/${APP_NAME}.env

echo "Database ${DB_NAME} created for ${APP_NAME}"
echo "Credentials saved to /home/administrator/secrets/${APP_NAME}.env"
```

## Future Development Plans
1. **Developer Self-Service** (planned):
   - Automated script like above for database creation
   - Web interface for database requests
   - Automatic backup inclusion

2. **Backup Automation**:
   - Scheduled backups via cron
   - Auto-discovery of all databases
   - Retention policy implementation

3. **Monitoring**:
   - Database size tracking
   - Connection monitoring
   - Performance metrics

## Related Services & Integration Points
- **TimescaleDB**: Separate time-series database on port 5433
- **MongoDB**: Document database on port 27017 (separate from PostgreSQL)
- **Redis**: Cache/session store on port 6379 (separate from PostgreSQL)
- **MCP Servers**: 
  - mcp-postgres: Database operations for Claude Code
  - mcp-memory-postgres: Memory storage (being phased out)
- **Applications Using PostgreSQL**:
  - Keycloak (dedicated instance)
  - Nextcloud (file storage metadata) - 17MB
  - OpenProject (project data) - 28MB, most active
  - Guacamole (connection configurations) - 9MB
  - PostfixAdmin (mail domains/users) - 8MB

## Performance & Monitoring
- **Current Load**: 9 active databases (after cleanup)
- **Uptime**: Main instance 12+ days stable
- **Memory Usage**: Monitor with `docker stats postgres`
- **Connection Pool**: Default max_connections = 100
- **Log Location**: `docker logs postgres`

## Backup Considerations
- **Critical**: postgres_data Docker volume (all databases)
- **Important**: Environment files and configuration
- **Scripts**: Backup and restore scripts in project directory
- **Location**: Defined by POSTGRES_BACKUP_DIR in postgres.env
- **Frequency**: Manual (automated backup planned)
- **Retention**: No policy yet (30 days recommended)

## Security Notes
- **Network Isolation**: postgres-net prevents external access
- **Port Exposure**: 5432 open for local/VPN access only
- **Authentication**: Password-based (consider cert-based for production)
- **User Separation**: Each application has dedicated database user
- **Secrets Management**: All passwords in secrets/*.env files
- **pgAdmin Access**: Restricted to administrators group via Keycloak

---
*Last Updated: 2025-09-05 by Claude*
*Next Review: When implementing automated backups*