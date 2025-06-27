#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Configuring Google Cloud Platform Firewall${NC}"
echo -e "${BLUE}==============================================${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found. Please install Google Cloud SDK first.${NC}"
    echo -e "${YELLOW}Visit: https://cloud.google.com/sdk/docs/install${NC}"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ No GCP project configured. Run: gcloud config set project YOUR_PROJECT_ID${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Current GCP Project: $PROJECT_ID${NC}"

# Create firewall rules for RAG system
echo -e "${YELLOW}🔥 Creating firewall rules for RAG system...${NC}"

# Allow Streamlit (8501)
gcloud compute firewall-rules create allow-streamlit \
    --allow tcp:8501 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow Streamlit UI access" \
    --project $PROJECT_ID 2>/dev/null || echo -e "${YELLOW}Rule 'allow-streamlit' may already exist${NC}"

# Allow FastAPI (8000)
gcloud compute firewall-rules create allow-fastapi \
    --allow tcp:8000 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow FastAPI access" \
    --project $PROJECT_ID 2>/dev/null || echo -e "${YELLOW}Rule 'allow-fastapi' may already exist${NC}"

# Allow N8N (5678)
gcloud compute firewall-rules create allow-n8n \
    --allow tcp:5678 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow N8N access" \
    --project $PROJECT_ID 2>/dev/null || echo -e "${YELLOW}Rule 'allow-n8n' may already exist${NC}"

# Allow HTTP (80) if not already allowed
gcloud compute firewall-rules create allow-http-rag \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP for RAG system" \
    --project $PROJECT_ID 2>/dev/null || echo -e "${YELLOW}HTTP rule may already exist${NC}"

# Allow HTTPS (443) if not already allowed
gcloud compute firewall-rules create allow-https-rag \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTPS for RAG system" \
    --project $PROJECT_ID 2>/dev/null || echo -e "${YELLOW}HTTPS rule may already exist${NC}"

# List current firewall rules
echo -e "${BLUE}📊 Current firewall rules:${NC}"
gcloud compute firewall-rules list --filter="allowed.ports:(8501 OR 8000 OR 5678 OR 80 OR 443)" --format="table(name,allowed[].map().firewall_rule().list():label=ALLOWED,sourceRanges.list():label=SRC_RANGES)" --project $PROJECT_ID

# Get instance information
echo -e "${BLUE}🖥️ Current compute instances:${NC}"
gcloud compute instances list --project $PROJECT_ID

echo -e "${GREEN}✅ GCP firewall configuration completed!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "${YELLOW}1. Ensure your compute instance is running${NC}"
echo -e "${YELLOW}2. Note your external IP address from the instance list above${NC}"
echo -e "${YELLOW}3. Test access: http://YOUR_EXTERNAL_IP:8501${NC}"
