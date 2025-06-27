#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing HTTP Deployment Issues${NC}"
echo -e "${BLUE}================================${NC}"

# Check if running as root or with sudo for firewall changes
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}Note: Some firewall commands may require sudo${NC}"
fi

# Fix firewall rules for HTTP deployment
echo -e "${YELLOW}🔥 Configuring firewall for HTTP deployment...${NC}"
sudo ufw allow 8501/tcp comment "Streamlit UI"
sudo ufw allow 8000/tcp comment "FastAPI"
sudo ufw allow 5678/tcp comment "N8N"

# Check current firewall status
echo -e "${BLUE}📊 Current firewall status:${NC}"
sudo ufw status

# Stop any existing containers
echo -e "${YELLOW}⏹️ Stopping existing containers...${NC}"
docker-compose down 2>/dev/null || true

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}📝 Creating .env file template...${NC}"
    cat > .env << 'EOF'
# API Keys (REQUIRED - Replace with your actual keys)
COHERE_API_KEY=your_cohere_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash-preview-04-17

# N8N Configuration
N8N_USER=admin
N8N_PASSWORD=admin123
N8N_ENCRYPTION_KEY=your-encryption-key-here

# Domain Configuration (for HTTPS)
DOMAIN=your-domain.com
EMAIL=your-email@example.com
EOF
    echo -e "${RED}⚠️ IMPORTANT: Edit .env file with your actual API keys!${NC}"
    echo -e "${YELLOW}Example: nano .env${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Rebuild containers to ensure latest configuration
echo -e "${YELLOW}🔨 Rebuilding containers with latest configuration...${NC}"
docker-compose build --no-cache

# Start containers
echo -e "${YELLOW}🚀 Starting containers...${NC}"
docker-compose up -d

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 30

# Check service status
echo -e "${BLUE}📊 Service status:${NC}"
docker-compose ps

# Test local connectivity
echo -e "${BLUE}🔍 Testing local connectivity:${NC}"
if curl -s http://localhost:8501/_stcore/health > /dev/null; then
    echo -e "${GREEN}✅ Streamlit is responding locally${NC}"
else
    echo -e "${RED}❌ Streamlit not responding locally${NC}"
fi

if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✅ FastAPI is responding locally${NC}"
else
    echo -e "${RED}❌ FastAPI not responding locally${NC}"
fi

if curl -s http://localhost:5678 > /dev/null; then
    echo -e "${GREEN}✅ N8N is responding locally${NC}"
else
    echo -e "${RED}❌ N8N not responding locally${NC}"
fi

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "Unable to detect")

echo -e "${GREEN}🌐 Access your services at:${NC}"
echo -e "${GREEN}   • Streamlit UI: http://$PUBLIC_IP:8501${NC}"
echo -e "${GREEN}   • API Documentation: http://$PUBLIC_IP:8000/docs${NC}"
echo -e "${GREEN}   • N8N Interface: http://$PUBLIC_IP:5678${NC}"
echo
echo -e "${YELLOW}📋 If external access still doesn't work:${NC}"
echo -e "${YELLOW}1. Check cloud provider firewall rules (GCP, AWS, Azure)${NC}"
echo -e "${YELLOW}2. Ensure ports 8501, 8000, 5678 are open in cloud console${NC}"
echo -e "${YELLOW}3. Verify no other services are using these ports${NC}"
echo -e "${YELLOW}4. Check container logs: docker-compose logs -f${NC}"

# Show logs if there are issues
echo -e "${BLUE}🔍 Recent container logs:${NC}"
docker-compose logs --tail=10

echo -e "${GREEN}✅ HTTP deployment fix completed!${NC}"
