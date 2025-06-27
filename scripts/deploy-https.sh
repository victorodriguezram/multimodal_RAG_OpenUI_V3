#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${1}"
EMAIL="${2}"

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo -e "${RED}Usage: $0 <domain> <email>${NC}"
    echo -e "${YELLOW}Example: $0 example.com admin@example.com${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Setting up HTTPS for Multimodal RAG System${NC}"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}Email: $EMAIL${NC}"

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root or with sudo${NC}"
   exit 1
fi

# Update system packages
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt-get update -y
apt-get install -y curl wget

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}🔧 Installing Docker Compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Update nginx configuration with actual domain
echo -e "${YELLOW}⚙️ Updating nginx configuration...${NC}"
# Check if the nginx conf.d directory exists and create if needed
if [ ! -d "nginx/conf.d" ]; then
    mkdir -p nginx/conf.d
    echo -e "${YELLOW}Created nginx/conf.d directory${NC}"
fi

# Check if default.conf exists, if not create it from template
if [ ! -f "nginx/conf.d/default.conf" ]; then
    echo -e "${YELLOW}Creating nginx configuration file...${NC}"
    cp nginx/conf.d/default.conf.template nginx/conf.d/default.conf 2>/dev/null || {
        echo -e "${RED}Error: nginx/conf.d/default.conf not found. Please ensure it exists.${NC}"
        exit 1
    }
fi

sed -i "s/your-domain.com/$DOMAIN/g" nginx/conf.d/default.conf
sed -i "s/your-email@example.com/$EMAIL/g" docker-compose-https.yml

# Create initial nginx config for certificate acquisition
echo -e "${YELLOW}🔒 Preparing for SSL certificate acquisition...${NC}"

# Stop any existing containers first
docker-compose -f docker-compose-https.yml down 2>/dev/null || true

# Create a minimal nginx config for Let's Encrypt challenge
cat > nginx/conf.d/initial.conf << EOF
server {
    listen 80 default_server;
    server_name $DOMAIN api.$DOMAIN n8n.$DOMAIN;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    # Temporary response for other requests
    location / {
        return 200 'SSL certificate acquisition in progress';
        add_header Content-Type text/plain;
    }
}
EOF

# Backup the main config temporarily
if [ -f "nginx/conf.d/default.conf" ]; then
    mv nginx/conf.d/default.conf nginx/conf.d/default.conf.backup
fi

# Create a basic nginx.conf if it doesn't exist
if [ ! -f "nginx/nginx.conf" ]; then
    echo -e "${YELLOW}Creating basic nginx.conf...${NC}"
    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=ui:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=api:10m rate=30r/s;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF
fi

# Start nginx for certificate challenge
echo -e "${YELLOW}🌐 Starting nginx for certificate acquisition...${NC}"

# Create a minimal docker-compose for certificate acquisition
cat > docker-compose-cert.yml << EOF
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/conf.d:/etc/nginx/conf.d
      - certbot_data:/var/www/certbot
    restart: "no"

volumes:
  certbot_data:
    driver: local
EOF

# Start only nginx for certificate challenge
docker-compose -f docker-compose-cert.yml up -d

# Wait for nginx to start and test it
sleep 10
echo -e "${BLUE}🔍 Testing nginx configuration...${NC}"

# Test if nginx is responding
if ! curl -s http://localhost/.well-known/acme-challenge/test 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Nginx test endpoint not responding, checking logs...${NC}"
    docker-compose -f docker-compose-cert.yml logs nginx
fi

# Check domain DNS resolution
echo -e "${BLUE}🔍 Checking DNS resolution for $DOMAIN...${NC}"
RESOLVED_IP=$(dig +short $DOMAIN | tail -n1)
CURRENT_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)

if [ -n "$RESOLVED_IP" ] && [ -n "$CURRENT_IP" ]; then
    if [ "$RESOLVED_IP" != "$CURRENT_IP" ]; then
        echo -e "${RED}⚠️ WARNING: DNS mismatch detected!${NC}"
        echo -e "${RED}   Domain $DOMAIN resolves to: $RESOLVED_IP${NC}"
        echo -e "${RED}   Server IP is: $CURRENT_IP${NC}"
        echo -e "${YELLOW}   Please update your DNS records before continuing.${NC}"
        echo -e "${YELLOW}   Would you like to continue anyway? (y/N)${NC}"
        read -r continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborting deployment. Please fix DNS first.${NC}"
            docker-compose -f docker-compose-cert.yml down
            rm -f docker-compose-cert.yml
            exit 1
        fi
    else
        echo -e "${GREEN}✅ DNS resolution correct: $DOMAIN -> $CURRENT_IP${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Could not verify DNS resolution${NC}"
fi

# Get SSL certificates
echo -e "${YELLOW}🔐 Acquiring SSL certificates...${NC}"

# Use standalone certbot approach for better reliability
docker-compose -f docker-compose-cert.yml down
rm -f docker-compose-cert.yml

# Try standalone method first (requires port 80 to be free)
echo -e "${BLUE}Attempting standalone certificate acquisition...${NC}"
docker run --rm \
    -p 80:80 \
    -v "$(pwd)/certbot_conf:/etc/letsencrypt" \
    -v "$(pwd)/certbot_data:/var/www/certbot" \
    certbot/certbot certonly \
    --standalone \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    --preferred-challenges http \
    -d $DOMAIN \
    -d api.$DOMAIN \
    -d n8n.$DOMAIN

# Check if certificates were created successfully
if [ -d "certbot_conf/live/$DOMAIN" ] && [ -f "certbot_conf/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${GREEN}✅ SSL certificates acquired successfully!${NC}"
else
    echo -e "${RED}❌ Certificate acquisition failed!${NC}"
    echo -e "${YELLOW}Common issues and solutions:${NC}"
    echo -e "${YELLOW}1. DNS: Ensure $DOMAIN points to this server's IP ($CURRENT_IP)${NC}"
    echo -e "${YELLOW}2. Firewall: Ensure port 80 is open and accessible from internet${NC}"
    echo -e "${YELLOW}3. Domain: Verify domain is properly registered and configured${NC}"
    echo -e "${YELLOW}4. Cloud: Check cloud provider firewall allows HTTP traffic${NC}"
    echo ""
    echo -e "${BLUE}To debug further:${NC}"
    echo -e "${BLUE}  - Test domain access: curl -v http://$DOMAIN${NC}"
    echo -e "${BLUE}  - Check DNS: dig $DOMAIN${NC}"
    echo -e "${BLUE}  - Verify firewall: sudo ufw status${NC}"
    echo ""
    exit 1
fi

# Restore main nginx config
echo -e "${YELLOW}🔧 Configuring nginx with SSL...${NC}"
rm -f nginx/conf.d/initial.conf
if [ -f "nginx/conf.d/default.conf.backup" ]; then
    mv nginx/conf.d/default.conf.backup nginx/conf.d/default.conf
fi

# Update docker-compose to use local certificate volumes
echo -e "${BLUE}Updating docker-compose configuration...${NC}"
sed -i "s|certbot_conf:/etc/letsencrypt|$(pwd)/certbot_conf:/etc/letsencrypt|g" docker-compose-https.yml 2>/dev/null || true
sed -i "s|certbot_data:/var/www/certbot|$(pwd)/certbot_data:/var/www/certbot|g" docker-compose-https.yml 2>/dev/null || true

# Stop any running containers
docker-compose -f docker-compose-https.yml down 2>/dev/null || true

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}📝 Creating .env file template...${NC}"
    cat > .env << EOF
# API Keys (REQUIRED - Replace with your actual keys)
COHERE_API_KEY=your_cohere_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash-preview-04-17

# N8N Configuration
N8N_USER=admin
N8N_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
N8N_DOMAIN=n8n.$DOMAIN

# Domain Configuration
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF
    echo -e "${RED}⚠️ IMPORTANT: Edit .env file with your actual API keys!${NC}"
fi

# Start the full system
echo -e "${YELLOW}🚀 Starting the complete system...${NC}"
docker-compose -f docker-compose-https.yml up -d

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 30

# Setup certificate renewal cron job
echo -e "${YELLOW}⏰ Setting up automatic certificate renewal...${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * * cd $(pwd) && docker-compose -f docker-compose-https.yml run --rm certbot renew --quiet && docker-compose -f docker-compose-https.yml exec nginx nginx -s reload") | crontab -

# Final status check
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${GREEN}🌐 Your services are available at:${NC}"
echo -e "${GREEN}   • Streamlit UI: https://$DOMAIN${NC}"
echo -e "${GREEN}   • API Documentation: https://api.$DOMAIN/docs${NC}"
echo -e "${GREEN}   • N8N Workflow: https://n8n.$DOMAIN${NC}"
echo
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "${YELLOW}1. Edit .env file with your actual API keys${NC}"
echo -e "${YELLOW}2. Restart services: docker-compose -f docker-compose-https.yml restart${NC}"
echo -e "${YELLOW}3. Test the endpoints above${NC}"
echo
echo -e "${BLUE}🔍 Check deployment status:${NC}"
echo -e "${BLUE}   docker-compose -f docker-compose-https.yml ps${NC}"
echo -e "${BLUE}   docker-compose -f docker-compose-https.yml logs -f${NC}"

# Check service status
echo -e "${BLUE}📊 Current service status:${NC}"
docker-compose -f docker-compose-https.yml ps
