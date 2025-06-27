#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 DNS and Domain Verification Tool${NC}"
echo -e "${BLUE}=================================${NC}"

# Get domain from user if not provided
if [ -z "$1" ]; then
    read -p "Enter your domain name (e.g., automatizatek.com): " DOMAIN
else
    DOMAIN="$1"
fi

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Domain name is required${NC}"
    exit 1
fi

echo -e "${BLUE}🌐 Checking domain: $DOMAIN${NC}"
echo ""

# Get current server IP
echo -e "${YELLOW}📊 Server Information:${NC}"
CURRENT_IP=$(curl -s --connect-timeout 10 ifconfig.me 2>/dev/null || curl -s --connect-timeout 10 icanhazip.com 2>/dev/null || curl -s --connect-timeout 10 ipinfo.io/ip 2>/dev/null)

if [ -n "$CURRENT_IP" ]; then
    echo -e "Current Server IP: ${GREEN}$CURRENT_IP${NC}"
else
    echo -e "Current Server IP: ${RED}Unable to detect${NC}"
fi
echo ""

# DNS Resolution Check
echo -e "${YELLOW}🔍 DNS Resolution:${NC}"

# Check main domain
if command -v dig &> /dev/null; then
    RESOLVED_IP=$(dig +short $DOMAIN @8.8.8.8 | tail -n1)
    if [ -n "$RESOLVED_IP" ]; then
        if [[ "$RESOLVED_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo -e "$DOMAIN resolves to: ${GREEN}$RESOLVED_IP${NC}"
            if [ "$RESOLVED_IP" = "$CURRENT_IP" ]; then
                echo -e "✅ ${GREEN}DNS correctly points to this server${NC}"
            else
                echo -e "❌ ${RED}DNS mismatch! Domain points to $RESOLVED_IP but server is $CURRENT_IP${NC}"
            fi
        else
            echo -e "$DOMAIN: ${RED}Invalid IP resolution: $RESOLVED_IP${NC}"
        fi
    else
        echo -e "$DOMAIN: ${RED}No A record found${NC}"
    fi
    
    # Check subdomains
    for subdomain in "api.$DOMAIN" "n8n.$DOMAIN"; do
        SUB_IP=$(dig +short $subdomain @8.8.8.8 | tail -n1)
        if [ -n "$SUB_IP" ] && [[ "$SUB_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo -e "$subdomain resolves to: ${GREEN}$SUB_IP${NC}"
            if [ "$SUB_IP" != "$CURRENT_IP" ]; then
                echo -e "❌ ${RED}Subdomain DNS mismatch!${NC}"
            fi
        else
            echo -e "$subdomain: ${YELLOW}No A record (will use main domain)${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️ dig command not available, using nslookup${NC}"
    nslookup $DOMAIN 8.8.8.8 | grep "Address:" | tail -1
fi
echo ""

# HTTP Connectivity Test
echo -e "${YELLOW}🌐 HTTP Connectivity Test:${NC}"

# Test direct IP access
if [ -n "$CURRENT_IP" ]; then
    echo -e "Testing HTTP access to server IP..."
    if timeout 10 curl -s -o /dev/null -w "%{http_code}" http://$CURRENT_IP 2>/dev/null | grep -q "200\|404\|502"; then
        echo -e "✅ ${GREEN}Server responds on HTTP${NC}"
    else
        echo -e "❌ ${RED}Server not responding on HTTP (check firewall)${NC}"
    fi
fi

# Test domain access
echo -e "Testing HTTP access to domain..."
HTTP_CODE=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN 2>/dev/null || echo "000")
case $HTTP_CODE in
    200|301|302)
        echo -e "✅ ${GREEN}Domain responds (HTTP $HTTP_CODE)${NC}"
        ;;
    404)
        echo -e "✅ ${GREEN}Domain reachable but no content (HTTP 404)${NC}"
        ;;
    000)
        echo -e "❌ ${RED}Domain not reachable (timeout/connection refused)${NC}"
        ;;
    *)
        echo -e "⚠️ ${YELLOW}Domain responds with HTTP $HTTP_CODE${NC}"
        ;;
esac
echo ""

# SSL Certificate Check
echo -e "${YELLOW}🔒 SSL Certificate Status:${NC}"
if [ -d "certbot_conf/live/$DOMAIN" ]; then
    echo -e "✅ ${GREEN}SSL certificates exist locally${NC}"
    
    # Check certificate validity
    if openssl x509 -in "certbot_conf/live/$DOMAIN/fullchain.pem" -noout -dates 2>/dev/null; then
        echo -e "Certificate details:"
        openssl x509 -in "certbot_conf/live/$DOMAIN/fullchain.pem" -noout -dates 2>/dev/null | sed 's/^/  /'
    fi
else
    echo -e "❌ ${RED}No SSL certificates found locally${NC}"
fi
echo ""

# Port Check
echo -e "${YELLOW}🔌 Port Accessibility:${NC}"
for port in 80 443; do
    if timeout 5 bash -c "</dev/tcp/$CURRENT_IP/$port" 2>/dev/null; then
        echo -e "✅ ${GREEN}Port $port is accessible${NC}"
    else
        echo -e "❌ ${RED}Port $port is not accessible${NC}"
    fi
done
echo ""

# Firewall Status
echo -e "${YELLOW}🔥 Firewall Status:${NC}"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null)
    if echo "$UFW_STATUS" | grep -q "Status: active"; then
        echo -e "UFW Status: ${GREEN}Active${NC}"
        if echo "$UFW_STATUS" | grep -q "80/tcp\|443/tcp"; then
            echo -e "✅ ${GREEN}HTTP/HTTPS ports allowed in UFW${NC}"
        else
            echo -e "❌ ${RED}HTTP/HTTPS ports not explicitly allowed in UFW${NC}"
        fi
    else
        echo -e "UFW Status: ${YELLOW}Inactive${NC}"
    fi
else
    echo -e "${YELLOW}UFW not available${NC}"
fi
echo ""

# Recommendations
echo -e "${BLUE}📋 RECOMMENDATIONS:${NC}"
echo -e "${BLUE}==================${NC}"

if [ -n "$RESOLVED_IP" ] && [ -n "$CURRENT_IP" ] && [ "$RESOLVED_IP" != "$CURRENT_IP" ]; then
    echo -e "${RED}🔧 CRITICAL: Fix DNS Records${NC}"
    echo -e "   Update your domain's A record to point to: $CURRENT_IP"
    echo -e "   Current DNS points to: $RESOLVED_IP"
    echo ""
fi

if [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}🔧 CRITICAL: Fix Network Connectivity${NC}"
    echo -e "   1. Check cloud provider firewall (allow HTTP/HTTPS)"
    echo -e "   2. Check server firewall: sudo ufw allow 80/tcp && sudo ufw allow 443/tcp"
    echo -e "   3. Ensure no other service is using port 80"
    echo ""
fi

echo -e "${GREEN}🚀 Next Steps for HTTPS Deployment:${NC}"
if [ -n "$RESOLVED_IP" ] && [ -n "$CURRENT_IP" ] && [ "$RESOLVED_IP" = "$CURRENT_IP" ] && [ "$HTTP_CODE" != "000" ]; then
    echo -e "   ✅ DNS and connectivity look good!"
    echo -e "   You can proceed with HTTPS deployment:"
    echo -e "   ./scripts/menu.sh -> option 8"
else
    echo -e "   ❌ Fix the issues above first, then retry HTTPS deployment"
fi

echo -e "${YELLOW}For Google Cloud Platform:${NC}"
echo -e "   Run: ./scripts/setup-gcp-firewall.sh"
echo ""
