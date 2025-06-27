#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Multimodal RAG Deployment Helper${NC}"
echo -e "${BLUE}====================================${NC}"
echo
echo "Choose your deployment option:"
echo "1) HTTP Only (for testing/development)"
echo "2) HTTPS with SSL certificates (for production)"
echo "3) Check current deployment status"
echo "4) View logs"
echo "5) Stop all services"
echo

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo -e "${YELLOW}🔧 Deploying with HTTP only...${NC}"
        
        # Check if .env exists
        if [ ! -f ".env" ]; then
            echo -e "${YELLOW}📝 Creating .env file from template...${NC}"
            cp .env.example .env
            echo -e "${RED}⚠️ IMPORTANT: Edit .env file with your actual API keys!${NC}"
            echo -e "${YELLOW}Press Enter to continue after editing .env file...${NC}"
            read
        fi
        
        # Deploy with HTTP
        docker-compose down 2>/dev/null || true
        docker-compose up -d
        
        echo -e "${GREEN}✅ HTTP deployment complete!${NC}"
        echo -e "${GREEN}🌐 Access your services at:${NC}"
        echo -e "${GREEN}   • Streamlit UI: http://localhost:8501${NC}"
        echo -e "${GREEN}   • API Documentation: http://localhost:8000/docs${NC}"
        echo -e "${GREEN}   • N8N Workflow: http://localhost:5678${NC}"
        echo -e "${GREEN}   • API Health: http://localhost:8000/health${NC}"
        echo
        echo -e "${YELLOW}📋 For external access, replace 'localhost' with your server's external IP${NC}"
        echo -e "${YELLOW}Note: N8N may show cookie warnings when accessed via external IP${NC}"
        ;;
        
    2)
        echo -e "${YELLOW}🔒 Setting up HTTPS deployment...${NC}"
        
        # Get domain and email
        read -p "Enter your domain name (e.g., example.com): " domain
        read -p "Enter your email address: " email
        
        if [ -z "$domain" ] || [ -z "$email" ]; then
            echo -e "${RED}❌ Domain and email are required for HTTPS setup${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}🔧 Running HTTPS deployment script...${NC}"
        chmod +x scripts/deploy-https.sh
        sudo scripts/deploy-https.sh "$domain" "$email"
        ;;
        
    3)
        echo -e "${BLUE}📊 Current deployment status:${NC}"
        echo
        echo "=== Docker Compose Services ==="
        docker-compose ps 2>/dev/null || echo "No HTTP services running"
        echo
        echo "=== HTTPS Services ==="
        docker-compose -f docker-compose-https.yml ps 2>/dev/null || echo "No HTTPS services running"
        echo
        echo "=== System Health Checks ==="
        echo -n "HTTP API Health: "
        curl -s http://localhost:8000/health 2>/dev/null && echo "✅ OK" || echo "❌ Failed"
        echo -n "HTTP Streamlit: "
        curl -s http://localhost:8501/_stcore/health 2>/dev/null && echo "✅ OK" || echo "❌ Failed"
        ;;
        
    4)
        echo -e "${BLUE}📝 Service logs:${NC}"
        echo
        echo "Choose which logs to view:"
        echo "1) HTTP deployment logs"
        echo "2) HTTPS deployment logs"
        echo "3) Specific service logs"
        
        read -p "Enter choice (1-3): " log_choice
        
        case $log_choice in
            1)
                docker-compose logs -f
                ;;
            2)
                docker-compose -f docker-compose-https.yml logs -f
                ;;
            3)
                echo "Available services: multimodal-rag, n8n, nginx, certbot"
                read -p "Enter service name: " service
                if docker-compose ps | grep -q "$service"; then
                    docker-compose logs -f "$service"
                elif docker-compose -f docker-compose-https.yml ps | grep -q "$service"; then
                    docker-compose -f docker-compose-https.yml logs -f "$service"
                else
                    echo -e "${RED}❌ Service not found${NC}"
                fi
                ;;
        esac
        ;;
        
    5)
        echo -e "${YELLOW}🛑 Stopping all services...${NC}"
        docker-compose down 2>/dev/null || true
        docker-compose -f docker-compose-https.yml down 2>/dev/null || true
        echo -e "${GREEN}✅ All services stopped${NC}"
        ;;
        
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo
echo -e "${BLUE}🔍 Useful commands:${NC}"
echo -e "${BLUE}   • Check status: docker-compose ps${NC}"
echo -e "${BLUE}   • View logs: docker-compose logs -f${NC}"
echo -e "${BLUE}   • Restart: docker-compose restart${NC}"
echo -e "${BLUE}   • Stop: docker-compose down${NC}"
