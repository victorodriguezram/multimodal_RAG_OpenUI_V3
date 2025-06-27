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
cat > nginx/conf.d/initial.conf << EOF
server {
    listen 80;
    server_name $DOMAIN api.$DOMAIN n8n.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# Backup the main config temporarily
mv nginx/conf.d/default.conf nginx/conf.d/default.conf.backup

# Start nginx for certificate challenge
echo -e "${YELLOW}🌐 Starting nginx for certificate acquisition...${NC}"
docker-compose -f docker-compose-https.yml up -d nginx

# Wait for nginx to start
sleep 15

# Get SSL certificates
echo -e "${YELLOW}🔐 Acquiring SSL certificates...${NC}"
docker-compose -f docker-compose-https.yml run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN \
    -d api.$DOMAIN \
    -d n8n.$DOMAIN

# Check if certificates were created successfully
if [ ! -f "/var/lib/docker/volumes/$(docker-compose -f docker-compose-https.yml config | grep certbot_conf | awk '{print $2}')/_data/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${RED}❌ Certificate acquisition failed!${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "${YELLOW}1. Domain DNS points to this server${NC}"
    echo -e "${YELLOW}2. Ports 80/443 are accessible${NC}"
    echo -e "${YELLOW}3. No other services using ports 80/443${NC}"
    exit 1
fi

# Restore main nginx config
echo -e "${YELLOW}🔧 Configuring nginx with SSL...${NC}"
rm nginx/conf.d/initial.conf
mv nginx/conf.d/default.conf.backup nginx/conf.d/default.conf

# Stop nginx temporarily
docker-compose -f docker-compose-https.yml down

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
