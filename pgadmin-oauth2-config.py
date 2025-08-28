##########################################################################
# pgAdmin OAuth2 Configuration for Keycloak SSO
##########################################################################

import os

# Enable server mode
SERVER_MODE = True

# Authentication configuration
AUTHENTICATION_SOURCES = ['oauth2', 'internal']

# OAuth2 Configuration
OAUTH2_CONFIG = [
    {
        'OAUTH2_NAME': 'Keycloak',
        'OAUTH2_DISPLAY_NAME': 'Keycloak SSO',
        'OAUTH2_CLIENT_ID': os.environ.get('PGADMIN_OAUTH2_CLIENT_ID', 'pgadmin'),
        'OAUTH2_CLIENT_SECRET': os.environ.get('PGADMIN_OAUTH2_CLIENT_SECRET'),
        'OAUTH2_TOKEN_URL': 'http://keycloak:8080/realms/master/protocol/openid-connect/token',
        'OAUTH2_AUTHORIZATION_URL': 'https://keycloak.ai-servicers.com/realms/master/protocol/openid-connect/auth',
        'OAUTH2_API_BASE_URL': 'http://keycloak:8080/realms/master/protocol/openid-connect/',
        'OAUTH2_USERINFO_ENDPOINT': 'http://keycloak:8080/realms/master/protocol/openid-connect/userinfo',
        'OAUTH2_SERVER_METADATA_URL': 'http://keycloak:8080/realms/master/.well-known/openid-configuration',
        'OAUTH2_SCOPE': 'openid email profile groups',
        'OAUTH2_ICON': 'fa-key',
        'OAUTH2_BUTTON_COLOR': '#007bff',
        
        # Auto-create users from OAuth2
        'OAUTH2_AUTO_CREATE_USER': True,
        
        # Username claim (what field from OAuth2 to use as username)
        'OAUTH2_USERNAME_CLAIM': 'preferred_username',
        
        # Email claim
        'OAUTH2_EMAIL_CLAIM': 'email',
        
        # SSL verification (disable for internal communication)
        'OAUTH2_SSL_CERT_VERIFICATION': False,
    }
]

# Master password for initial setup (only used if no users exist)
MASTER_PASSWORD_REQUIRED = False

# Auto-provisioning configuration
# Map OAuth2 groups to pgAdmin roles
OAUTH2_GROUP_ROLE_MAPPING = {
    '/administrators': 'Administrator',  # Full access
    '/developers': 'User',  # Limited access
}

# Additional security settings
ENHANCED_COOKIE_PROTECTION = False  # Set to False for OAuth2 proxy compatibility
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_SAMESITE = 'Lax'

# Allow OAuth2 proxy headers
PROXY_X_FOR_COUNT = 1
PROXY_X_PROTO_COUNT = 1
PROXY_X_HOST_COUNT = 1
PROXY_X_PORT_COUNT = 1
PROXY_X_PREFIX_COUNT = 1

# Logging
CONSOLE_LOG_LEVEL = 20  # INFO level
FILE_LOG_LEVEL = 20