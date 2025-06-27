#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 RAG System Deployment Troubleshooting${NC}"
echo -e "${BLUE}=======================================${NC}"

# Function to check port availability
check_port() {
    local port=$1
    local service=$2
    echo -e "${BLUE}🔍 Checking port $port ($service)...${NC}"
    
    # Check if port is listening
    if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✅ Port $port is listening${NC}"
        
        # Check local connectivity
        if curl -s --connect-timeout 5 http://localhost:$port > /dev/null; then
            echo -e "${GREEN}✅ $service responds locally on port $port${NC}"
        else
            echo -e "${YELLOW}⚠️ $service port $port listening but not responding${NC}"
        fi
    else
        echo -e "${RED}❌ Port $port is not listening${NC}"
    fi
}

# Function to check external connectivity
check_external_access() {
    local port=$1
    local service=$2
    
    # Get external IP
    EXTERNAL_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 icanhazip.com 2>/dev/null)
    
    if [ -n "$EXTERNAL_IP" ]; then
        echo -e "${BLUE}🌐 Testing external access to $service on $EXTERNAL_IP:$port${NC}"
        
        # Test from inside the server (may work even if external doesn't)
        if timeout 10 curl -s http://$EXTERNAL_IP:$port > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service accessible externally on $EXTERNAL_IP:$port${NC}"
        else
            echo -e "${RED}❌ $service NOT accessible externally on $EXTERNAL_IP:$port${NC}"
            echo -e "${YELLOW}   This suggests firewall or network configuration issues${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Could not determine external IP${NC}"
    fi
}

# System information
echo -e "${BLUE}📊 System Information:${NC}"
echo -e "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
echo -e "Kernel: $(uname -r)"
echo -e "Architecture: $(uname -m)"
echo

# Docker status
echo -e "${BLUE}🐳 Docker Status:${NC}"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker service is running${NC}"
    docker --version
else
    echo -e "${RED}❌ Docker service is not running${NC}"
    echo -e "${YELLOW}Try: sudo systemctl start docker${NC}"
fi
echo

# Docker Compose status
echo -e "${BLUE}📋 Docker Compose Status:${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose is available${NC}"
    docker-compose --version
else
    echo -e "${RED}❌ Docker Compose not found${NC}"
fi
echo

# Container status
echo -e "${BLUE}📦 Container Status:${NC}"
if docker-compose ps 2>/dev/null | grep -q "Up"; then
    echo -e "${GREEN}✅ Some containers are running${NC}"
    docker-compose ps
else
    echo -e "${RED}❌ No containers are running or docker-compose.yml not found${NC}"
    echo -e "${YELLOW}Try: docker-compose up -d${NC}"
fi
echo

# Check specific ports
check_port 8501 "Streamlit"
check_port 8000 "FastAPI"
check_port 5678 "N8N"
echo

# UFW Firewall status
echo -e "${BLUE}🔥 UFW Firewall Status:${NC}"
if command -v ufw &> /dev/null; then
    ufw_status=$(sudo ufw status 2>/dev/null)
    if echo "$ufw_status" | grep -q "Status: active"; then
        echo -e "${GREEN}✅ UFW is active${NC}"
        echo "$ufw_status" | grep -E "(8501|8000|5678|80|443)"
    else
        echo -e "${YELLOW}⚠️ UFW is inactive${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ UFW not installed${NC}"
fi
echo

# Check iptables rules
echo -e "${BLUE}🔧 Network Rules:${NC}"
if iptables -L INPUT 2>/dev/null | grep -q "DROP\|REJECT"; then
    echo -e "${YELLOW}⚠️ Restrictive iptables rules detected${NC}"
    echo -e "${YELLOW}   This might block external connections${NC}"
else
    echo -e "${GREEN}✅ No obvious iptables restrictions${NC}"
fi
echo

# External connectivity test
check_external_access 8501 "Streamlit"
check_external_access 8000 "FastAPI" 
check_external_access 5678 "N8N"
echo

# Environment file check
echo -e "${BLUE}📝 Configuration Check:${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env file exists${NC}"
    if grep -q "your_.*_key_here" .env; then
        echo -e "${RED}❌ .env contains placeholder values - update with real API keys${NC}"
    else
        echo -e "${GREEN}✅ .env appears to have real values${NC}"
    fi
else
    echo -e "${RED}❌ .env file missing${NC}"
    echo -e "${YELLOW}   Create one with: cp .env.example .env${NC}"
fi
echo

# Docker network check
echo -e "${BLUE}🌐 Docker Network:${NC}"
if docker network ls | grep -q rag_network; then
    echo -e "${GREEN}✅ RAG network exists${NC}"
else
    echo -e "${YELLOW}⚠️ RAG network not found${NC}"
fi
echo

# Recent logs
echo -e "${BLUE}📄 Recent Container Logs:${NC}"
if docker-compose ps -q 2>/dev/null | head -1 | xargs docker logs --tail=5 2>/dev/null; then
    echo -e "${GREEN}✅ Container logs shown above${NC}"
else
    echo -e "${RED}❌ No container logs available${NC}"
fi
echo

# Summary and recommendations
echo -e "${BLUE}📋 SUMMARY & RECOMMENDATIONS:${NC}"
echo -e "${YELLOW}==================================${NC}"

if ! systemctl is-active --quiet docker; then
    echo -e "${RED}🔧 CRITICAL: Start Docker service${NC}"
    echo -e "   sudo systemctl start docker"
    echo -e "   sudo systemctl enable docker"
fi

if ! docker-compose ps 2>/dev/null | grep -q "Up"; then
    echo -e "${RED}🔧 CRITICAL: Start containers${NC}"
    echo -e "   docker-compose up -d"
fi

if [ -f ".env" ] && grep -q "your_.*_key_here" .env; then
    echo -e "${RED}🔧 CRITICAL: Update .env with real API keys${NC}"
    echo -e "   Edit .env file and replace placeholder values"
fi

echo -e "${YELLOW}🔧 FOR EXTERNAL ACCESS ISSUES:${NC}"
echo -e "   1. Check cloud provider firewall (GCP/AWS/Azure console)"
echo -e "   2. Ensure ports 8501, 8000, 5678 are open in cloud firewall"
echo -e "   3. For GCP: run ./scripts/setup-gcp-firewall.sh"
echo -e "   4. Restart containers: docker-compose restart"

EXTERNAL_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null)
if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}🌐 Your external IP: $EXTERNAL_IP${NC}"
    echo -e "${GREEN}   Test URLs:${NC}"
    echo -e "${GREEN}   • http://$EXTERNAL_IP:8501 (Streamlit)${NC}"
    echo -e "${GREEN}   • http://$EXTERNAL_IP:8000/docs (FastAPI)${NC}"
    echo -e "${GREEN}   • http://$EXTERNAL_IP:5678 (N8N)${NC}"
fi

echo -e "${BLUE}✅ Troubleshooting completed!${NC}"
