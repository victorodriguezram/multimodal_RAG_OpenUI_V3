# 🔍 Multimodal RAG System with Docker Compose & N8N Integration

A production-ready containerized deployment of a **Multimodal Retrieval-Augmented Generation (RAG)** system that combines **multimodal embeddings** with **Gemini 2.5 Flash** for answering questions from both text and images in PDF documents. This system includes complete HTTP and HTTPS deployment options with SSL certificate automation.

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Options](#deployment-options)
- [Script Management](#script-management)
- [HTTPS Production Setup](#https-production-setup)
- [Complete Rebuild](#complete-rebuild-for-dependency-issues)
- [Complete Docker Cleanup](#complete-docker-cleanup-before-redeployment)
- [Architecture](#architecture)
- [API Documentation](#api-documentation)
- [N8N Integration](#n8n-integration)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## 🏗️ System Overview

This system transforms PDF documents into a searchable multimodal knowledge base by:
1. **Extracting** both text content and page images from PDFs
2. **Embedding** content using Cohere's Embed-v4.0 multimodal model
3. **Storing** embeddings in FAISS vector database for fast similarity search
4. **Retrieving** relevant context (text or images) based on user queries
5. **Generating** contextual answers using Google's Gemini 2.5 Flash model

### Key Features
- ✅ **Multimodal RAG** (text + visual embeddings)
- ✅ **Production-ready Docker deployment**
- ✅ **REST API for automation integration**
- ✅ **N8N workflow automation support**
- ✅ **Streamlit web interface**
- ✅ **Ubuntu Server optimized**
- ✅ **Persistent data storage**

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu Server 20.04+ (recommended) or Ubuntu Desktop
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: 10GB free space minimum
- **CPU**: 2+ cores recommended

### Required Software
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

### API Keys Required
- **Cohere API Key**: Sign up at [Cohere Dashboard](https://dashboard.cohere.com/)
- **Gemini API Key**: Get access via [Google AI Studio](https://aistudio.google.com/)

### Ubuntu Server Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Install Git
sudo apt install git -y

# Logout and login again to apply Docker group membership
```

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd multimodal_RAG_OpenUI_V2
```

### 2. Configure Environment Variables
```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

Add your API keys to the `.env` file:
```bash
# API Keys (REQUIRED)
COHERE_API_KEY=your_cohere_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash-preview-04-17

# N8N Configuration
N8N_USER=admin
N8N_PASSWORD=your_secure_password_here
N8N_ENCRYPTION_KEY=your_32_character_encryption_key_here

# Domain Configuration (for HTTPS)
DOMAIN=your-domain.com
EMAIL=your-email@example.com
```

### 3. Choose Your Deployment Option

#### Option A: Interactive Script Manager (Recommended)
```bash
# Run the interactive script manager
chmod +x scripts/menu.sh
./scripts/menu.sh
```

#### Option B: Quick Deployment Script
```bash
# Run the quick deployment helper
chmod +x scripts/quick-deploy.sh
./scripts/quick-deploy.sh
```

#### Option C: Manual Deployment
```bash
# For HTTP deployment (testing)
docker-compose up -d

# For HTTPS deployment (production)
chmod +x scripts/deploy-https.sh
sudo ./scripts/deploy-https.sh your-domain.com your-email@example.com
```

## 🚀 Deployment Options

### 1. HTTP Deployment (Development/Testing)
- **Use Case**: Local development, testing, internal networks
- **Access**: `http://your-server-ip:port`
- **SSL**: None
- **Command**: Use script manager option 7 or `docker-compose up -d`

### 2. HTTPS Deployment (Production)
- **Use Case**: Production deployment with domain name
- **Access**: `https://your-domain.com`
- **SSL**: Automated Let's Encrypt certificates
- **Requirements**: Domain name, DNS configuration
- **Command**: Use script manager option 8 or `scripts/deploy-https.sh`

### Access Points

#### HTTP Deployment:
- **Streamlit UI**: `http://your-server-ip:8501`
- **API Documentation**: `http://your-server-ip:8000/docs`
- **N8N Interface**: `http://your-server-ip:5678`
- **API Health**: `http://your-server-ip:8000/health`

#### HTTPS Deployment:
- **Streamlit UI**: `https://your-domain.com`
- **API Documentation**: `https://api.your-domain.com/docs`
- **N8N Interface**: `https://n8n.your-domain.com`
- **API Health**: `https://api.your-domain.com/health`

## 📋 Script Management

### Interactive Script Manager
The system includes a comprehensive script manager for easy deployment and maintenance:

```bash
chmod +x scripts/menu.sh
./scripts/menu.sh
```

### Available Scripts:

#### 🚀 Installation & Setup:
- **check-deps.sh** - System Prerequisites Check
- **check-env.sh** - Environment Configuration Check  
- **setup.sh** - Full System Setup
- **fix-versions.sh** - Fix Package Version Issues

#### 🔧 Deployment & Maintenance:
- **quick-deploy.sh** - Interactive Deployment (HTTP/HTTPS)
- **deploy.sh** - HTTP Deployment for Testing
- **deploy-https.sh** - HTTPS Production Deployment with SSL
- **rebuild.sh** - Rebuild Containers
- **validate.sh** - Validate Deployment
- **start.sh** - Container Startup Script

#### 🧹 Cleanup & Troubleshooting:
- **cleanup-targeted.sh** - Safe Project Cleanup
- **cleanup-full.sh** - Full Project Resource Removal
- **cleanup-nuclear.sh** - ⚠️ Complete Docker System Cleanup
- **fix-http-deployment.sh** - Fix External Access Issues for HTTP
- **setup-gcp-firewall.sh** - Configure Google Cloud Firewall Rules
- **troubleshoot-deployment.sh** - Comprehensive Deployment Diagnostics

#### 📋 Management:
- **menu.sh** - Interactive Script Manager

## 🔒 HTTPS Production Setup

For production deployment with SSL certificates:

### Prerequisites:
1. **Domain Name**: You must own a domain (e.g., `example.com`)
2. **DNS Configuration**: Point your domain to your server's IP
3. **Firewall**: Open ports 80 and 443

### DNS Records Required:
```
Type: A    Name: @              Value: YOUR_SERVER_IP
Type: A    Name: api            Value: YOUR_SERVER_IP  
Type: A    Name: n8n            Value: YOUR_SERVER_IP
```

### Google Cloud Firewall (if using GCP):
```bash
# Allow HTTP traffic
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 --source-ranges 0.0.0.0/0

# Allow HTTPS traffic
gcloud compute firewall-rules create allow-https \
    --allow tcp:443 --source-ranges 0.0.0.0/0
```

### HTTPS Deployment:
```bash
# Method 1: Using script manager
./scripts/menu.sh
# Choose option 8, enter your domain and email

# Method 2: Direct script execution
chmod +x scripts/deploy-https.sh
sudo ./scripts/deploy-https.sh your-domain.com your-email@example.com
```

### Features:
- ✅ Automated SSL certificate acquisition and renewal
- ✅ Nginx reverse proxy with security headers
- ✅ Rate limiting and DDoS protection
- ✅ WebSocket support for real-time features
- ✅ Proper subdomain routing

## 🔄 Complete Rebuild (For Dependency Issues)

If you encounter import errors (like missing `faiss` module) or want to ensure a clean build:

### Automated Rebuild (Recommended)
```bash
# Use the interactive script manager
./scripts/menu.sh
# Then select option 9 (Rebuild Containers)

# Or run directly
chmod +x scripts/rebuild.sh
./scripts/rebuild.sh
```

**CRITICAL**: Update `.env` with your actual API keys (NO quotes around values):
```env
COHERE_API_KEY=co_your_actual_cohere_key_here
GEMINI_API_KEY=AIza_your_actual_gemini_key_here
GEMINI_MODEL=gemini-2.5-flash-preview-04-17
N8N_USER=admin
N8N_PASSWORD=your_secure_password_here
N8N_ENCRYPTION_KEY=your_secure_encryption_key_here
```

**⚠️ Important Notes:**
- Replace `co_your_actual_cohere_key_here` with your real Cohere API key from https://dashboard.cohere.com/
- Replace `AIza_your_actual_gemini_key_here` with your real Gemini API key from https://aistudio.google.com/
- Do NOT use quotes around the values
- Do NOT leave placeholder text like `your_COHERE_API_KEY_here`

### 3. Deploy the System
```bash
# OPTION 1: Use the interactive script menu (RECOMMENDED)
chmod +x scripts/menu.sh
./scripts/menu.sh
# Then select option 2 to verify environment, then option 6 for interactive deployment

# OPTION 2: Quick deployment helper
chmod +x scripts/quick-deploy.sh
./scripts/quick-deploy.sh

# OPTION 3: Manual deployment
# IMPORTANT: Verify your .env configuration first
chmod +x scripts/check-env.sh
./scripts/check-env.sh

# For HTTP deployment
docker-compose up -d

# For HTTPS deployment (requires domain)
chmod +x scripts/deploy-https.sh
sudo ./scripts/deploy-https.sh your-domain.com your-email@example.com

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Access the Applications

#### HTTP Deployment (Development/Testing):
- **Streamlit UI**: http://localhost:8501 or http://your-server-ip:8501
- **API Documentation**: http://localhost:8000/docs or http://your-server-ip:8000/docs
- **N8N Interface**: http://localhost:5678 or http://your-server-ip:5678
- **API Health Check**: http://localhost:8000/health or http://your-server-ip:8000/health

**⚠️ Important for External Access:**
- Ensure your cloud provider firewall allows ports 8501, 8000, and 5678
- For GCP users: Run `./scripts/setup-gcp-firewall.sh` to configure firewall rules
- If external access fails, run `./scripts/troubleshoot-deployment.sh` for diagnostics

#### HTTPS Deployment (Production):
- **Streamlit UI**: https://your-domain.com
- **API Documentation**: https://api.your-domain.com/docs
- **N8N Interface**: https://n8n.your-domain.com
- **API Health Check**: https://api.your-domain.com/health
- **API Documentation**: http://localhost:8000/docs
- **N8N Interface**: http://localhost:5678
  - Username: admin
  - Password: (as set in .env file)

### 5. Verify Deployment
```bash
# Check API health
curl http://localhost:8000/health

# Check system status
curl http://localhost:8000/status
```

## � Script Management

All utility scripts have been organized in the `/scripts` folder for better organization. You can use the interactive script manager for easy access:

### Interactive Script Manager (Recommended)
```bash
# Launch the interactive script menu
chmod +x scripts/menu.sh
./scripts/menu.sh
```

The script manager provides a categorized menu with:

**🚀 Installation & Setup:**
- System prerequisites check
- Environment configuration verification
- Dependencies validation
- Full automated setup
- Package version fixes

**🔧 Deployment & Maintenance:**
- Interactive deployment (HTTP/HTTPS)
- HTTP deployment for testing
- HTTPS deployment with SSL
- Container rebuild
- Container rebuilding
- Deployment validation

**🧹 Cleanup & Troubleshooting:**
- Targeted cleanup (safe)
- Full project cleanup
- Nuclear cleanup (⚠️ removes all Docker resources)

### Manual Script Execution
```bash
# Run individual scripts directly
./scripts/check-env.sh          # Check environment
./scripts/quick-deploy.sh       # Interactive deployment
./scripts/deploy-https.sh       # HTTPS deployment
./scripts/rebuild.sh            # Rebuild containers
./scripts/cleanup-targeted.sh   # Clean up project resources
```

### Script Categories
- **Setup Scripts**: `check-deps.sh`, `check-env.sh`, `setup.sh`, `fix-versions.sh`
- **Deployment Scripts**: `deploy.sh`, `rebuild.sh`, `validate.sh`
- **Cleanup Scripts**: `cleanup-targeted.sh`, `cleanup-full.sh`, `cleanup-nuclear.sh`

See `/scripts/README.md` for detailed script documentation.

## �🔄 Complete Rebuild (For Dependency Issues)

If you encounter import errors (like missing `faiss` module) or want to ensure a clean build:

### Automated Rebuild
```bash
# Use the automated rebuild script
chmod +x scripts/rebuild.sh
./scripts/rebuild.sh
```

### Manual Rebuild
```bash
# Stop and remove containers with volumes
docker-compose down -v --remove-orphans

# Remove the application image to force rebuild
docker rmi multimodal_rag_openui_v2-multimodal-rag 2>/dev/null || true

# Build from scratch (no cache)
docker-compose build --no-cache

# Start containers
docker-compose up -d

# Check if import test passes
docker-compose exec multimodal-rag python debug_imports.py
```

### Import Debugging
```bash
# Test all Python imports inside the container
docker-compose exec multimodal-rag python debug_imports.py

# View startup logs for errors
docker-compose logs multimodal-rag

# Interactive debugging session
docker-compose exec multimodal-rag /bin/bash
```

## 🏛️ Architecture

### Container Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Compose Network                  │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │  multimodal-rag  │    │       n8n        │              │
│  │                  │    │                  │              │
│  │  ┌─────────────┐ │    │  Workflow Engine │              │
│  │  │ Streamlit   │ │    │  - HTTP Requests │              │
│  │  │    :8501    │ │    │  - Webhooks      │              │
│  │  └─────────────┘ │    │  - Automation    │              │
│  │                  │    │      :5678       │              │
│  │  ┌─────────────┐ │    └──────────────────┘              │
│  │  │  FastAPI    │ │                                      │
│  │  │    :8000    │ │                                      │
│  │  └─────────────┘ │                                      │
│  └──────────────────┘                                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │   Persistent     │    │    Persistent    │              │
│  │   RAG Data       │    │    N8N Data      │              │
│  │   - FAISS Index  │    │   - Workflows    │              │
│  │   - Documents    │    │   - Credentials  │              │
│  │   - Images       │    │   - Executions   │              │
│  └──────────────────┘    └──────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow
1. **Document Ingestion**: PDFs → Text Extraction + Image Conversion
2. **Embedding Generation**: Cohere Embed-v4.0 → Vector Embeddings
3. **Storage**: FAISS Index + Metadata in Pickle files
4. **Query Processing**: User Query → Embedding → Similarity Search
5. **Answer Generation**: Retrieved Context + Gemini 2.5 Flash → Response

## 📖 API Documentation

### Base URL
- Local: `http://localhost:8000`
- Production: `http://your-server-ip:8000`

### Core Endpoints

#### 1. Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "multimodal-rag-api"
}
```

#### 2. System Status
```http
GET /status
```

**Response:**
```json
{
  "status": "active",
  "total_documents": 15,
  "text_documents": 5,
  "image_documents": 10,
  "faiss_index_size": 15
}
```

#### 3. Upload Documents
```http
POST /documents/upload
Content-Type: multipart/form-data
```

**Request:**
```bash
curl -X POST "http://localhost:8000/documents/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "files=@document1.pdf" \
  -F "files=@document2.pdf"
```

#### 4. Query Documents
```http
POST /query
Content-Type: application/json
```

**Request:**
```bash
curl -X POST "http://localhost:8000/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the profit margin of Visa?",
    "top_k": 3
  }'
```

#### 5. List Documents
```http
GET /documents
```

#### 6. Clear All Documents
```http
DELETE /documents/clear
```

## 🔄 N8N Integration

### Accessing N8N
1. Navigate to `http://localhost:5678`
2. Login with credentials from `.env` file

### Setting Up RAG Workflows

#### Basic Query Workflow
1. **Webhook Trigger Node**:
   - Method: `POST`
   - Path: `/rag-query`

2. **HTTP Request Node**:
   - Method: `POST`
   - URL: `http://multimodal-rag:8000/query`
   - Headers: `Content-Type: application/json`
   - Body:
   ```json
   {
     "query": "{{ $json.query }}",
     "top_k": 3
   }
   ```

3. **Response Node**: Return the answer to the webhook caller

### N8N Best Practices
- **Error Handling**: Always add error handling nodes for API calls
- **Rate Limiting**: Implement delays between bulk operations
- **Logging**: Use function nodes to log important data
- **Validation**: Validate inputs before sending to RAG API

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `COHERE_API_KEY` | Cohere API key for embeddings | - | Yes |
| `GEMINI_API_KEY` | Google Gemini API key | - | Yes |
| `GEMINI_MODEL` | Gemini model version | `gemini-2.5-flash-preview-04-17` | No |
| `N8N_USER` | N8N admin username | `admin` | No |
| `N8N_PASSWORD` | N8N admin password | `admin123` | No |
| `N8N_ENCRYPTION_KEY` | N8N encryption key | - | Yes |

### Port Configuration

| Service | Internal Port | External Port | Purpose |
|---------|---------------|---------------|---------|
| Streamlit | 8501 | 8501 | Web UI |
| FastAPI | 8000 | 8000 | REST API |
| N8N | 5678 | 5678 | Automation Platform |

## 🧹 Complete Docker Cleanup (Before Redeployment)

If you need to completely remove all Docker resources from previous deployments, you can use the script manager:

### Option 1: Use Script Manager (Recommended)
```bash
# Run the script manager
chmod +x scripts/menu.sh
./scripts/menu.sh

# Choose option 11 (Targeted Cleanup) - Safe, removes only project resources
# Choose option 12 (Full Cleanup) - Removes all project resources including volumes
# Choose option 13 (Nuclear Cleanup) - ⚠️ WARNING: Removes ALL Docker resources
```

### Option 2: Manual Cleanup Commands

#### Targeted Cleanup (Safer)
```bash
# Stop and remove only our project containers
docker-compose down --remove-orphans --volumes --rmi all
docker-compose -f docker-compose-https.yml down --remove-orphans --volumes --rmi all 2>/dev/null || true

# Or use the script directly
chmod +x scripts/cleanup-targeted.sh
./scripts/cleanup-targeted.sh
```

#### Nuclear Cleanup (Removes Everything)
```bash
# Use the nuclear cleanup script
chmod +x scripts/cleanup-nuclear.sh
./scripts/cleanup-nuclear.sh

# Or manually:
# Stop all running containers
docker stop $(docker ps -aq) 2>/dev/null || true

# Remove all containers (running and stopped)
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove ALL Docker images (including base images)
docker rmi $(docker images -q) -f 2>/dev/null || true

# Remove all volumes
docker volume rm $(docker volume ls -q) 2>/dev/null || true

# Remove all custom networks
docker network rm $(docker network ls --filter type=custom -q) 2>/dev/null || true

# Remove all build cache and unused data
docker system prune -a --volumes -f

# Remove all builder cache
docker builder prune -a -f
```

# Remove specific images if they exist
docker rmi multimodal_rag_openui_v2-multimodal-rag:latest 2>/dev/null || true
docker rmi n8nio/n8n:latest 2>/dev/null || true
docker rmi python:3.10-slim 2>/dev/null || true

# Remove specific volumes
docker volume rm multimodal_rag_openui_v2_rag_data 2>/dev/null || true
docker volume rm multimodal_rag_openui_v2_uploaded_files 2>/dev/null || true
docker volume rm multimodal_rag_openui_v2_n8n_data 2>/dev/null || true

# Clean up unused images and cache
docker image prune -a -f
docker system prune -f
```

### Option 3: Step-by-Step Verification
```bash
# 1. Check what's currently running
echo "=== Current Docker State ==="
docker ps -a
docker images
docker volume ls
docker network ls

# 2. Stop our specific containers
echo "=== Stopping Project Containers ==="
docker stop $(docker ps -q --filter "name=multimodal") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=n8n") 2>/dev/null || true

# 3. Remove our specific containers
echo "=== Removing Project Containers ==="
docker rm $(docker ps -aq --filter "name=multimodal") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=n8n") 2>/dev/null || true

# 4. Remove our specific images
echo "=== Removing Project Images ==="
docker images | grep -E "(multimodal|n8n)" | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true

# 5. Remove our specific volumes
echo "=== Removing Project Volumes ==="
docker volume ls | grep multimodal | awk '{print $2}' | xargs docker volume rm 2>/dev/null || true

# 6. Check ports are free
echo "=== Checking Port Availability ==="
sudo netstat -tulpn | grep -E ":(8000|8501|5678)" || echo "All ports are free"

# 7. Final cleanup
echo "=== Final Cleanup ==="
docker system prune -f
```

### Port Conflict Resolution
```bash
# Check what's using the ports
sudo lsof -i :8000
sudo lsof -i :8501
sudo lsof -i :5678

# Kill processes if needed (replace PID with actual process ID)
sudo kill -9 <PID>

# Alternative: Kill all processes on specific ports
sudo fuser -k 8000/tcp 2>/dev/null || true
sudo fuser -k 8501/tcp 2>/dev/null || true
sudo fuser -k 5678/tcp 2>/dev/null || true
```

### Verification After Cleanup
```bash
# Verify everything is clean
echo "=== Verification ==="
echo "Containers: $(docker ps -aq | wc -l)"
echo "Images: $(docker images -q | wc -l)"
echo "Volumes: $(docker volume ls -q | wc -l)"
echo "Networks: $(docker network ls --filter type=custom -q | wc -l)"

# Should all return 0 or very few items
docker ps -a
docker images
docker volume ls
```

### Quick One-Liner Cleanup
```bash
# Complete cleanup in one command
docker stop $(docker ps -aq); docker rm $(docker ps -aq); docker rmi $(docker images -q) -f; docker volume rm $(docker volume ls -q); docker system prune -a --volumes -f; docker builder prune -a -f
```

**⚠️ Warning**: The nuclear cleanup will remove ALL Docker images, containers, and volumes on your system. Use the targeted cleanup if you have other Docker projects.

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Container Startup Issues
```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs multimodal-rag
docker-compose logs n8n
```

**Solutions**:
- Ensure sufficient memory (4GB+ recommended)
- Verify API keys are correctly set in `.env`
- Check port availability

#### 2. API Key Issues
```bash
# Check logs for API errors
docker-compose logs multimodal-rag | grep -i "error"
```

**Solutions**:
- Verify Cohere API key at https://dashboard.cohere.com/
- Verify Gemini API key at https://aistudio.google.com/
- Check API quotas and billing status

#### 3. Configuration File Issues
**Problem**: `NameError: name 'your_COHERE_API_KEY_here' is not defined`
```bash
# Check if config.py is properly using environment variables
docker-compose exec multimodal-rag cat config.py
```

**Solutions**:
- Ensure .env file exists with proper API keys (no quotes around values)
- Rebuild containers after config changes: `docker-compose build --no-cache`
- Verify environment variables are loaded: `docker-compose exec multimodal-rag env | grep API`
- Check .env file format:
  ```env
  COHERE_API_KEY=co_your_actual_key_here
  GEMINI_API_KEY=AIza_your_actual_key_here
  ```

#### 4. Missing Dependencies (FAISS)
**Problem**: `ModuleNotFoundError: No module named 'faiss'`
```bash
# Check if faiss-cpu is in requirements
docker-compose exec multimodal-rag pip list | grep faiss

# Test all imports
docker-compose exec multimodal-rag python debug_imports.py
```

**Solutions**:
- **Rebuild containers** with updated requirements: `docker-compose build --no-cache`
- Ensure both `requirements.txt` and `api_requirements.txt` include `faiss-cpu==1.7.4`
- Use the automated rebuild script: `./scripts/rebuild.sh`
- For manual fix: `docker-compose exec multimodal-rag pip install faiss-cpu==1.7.4`

#### 5. Package Version Issues
**Problem**: `ERROR: Could not find a version that satisfies the requirement cohere==4.21.1`
```bash
# Check available package versions
pip index versions cohere
```

**Solutions**:
- **Updated package versions** in requirements files
- Use `cohere==4.57` (latest stable version)
- Use `google-generativeai==0.8.3` (latest compatible version)
- **Rebuild containers** after version updates: `docker-compose build --no-cache`

**Troubleshooting Steps**:
```bash
# 1. Check which requirements files exist
ls -la *requirements*.txt

# 2. Verify package versions are valid
grep -E "(cohere|google-generativeai|faiss)" requirements.txt api_requirements.txt

# 3. Complete rebuild if needed
docker-compose down -v --remove-orphans
docker rmi multimodal_rag_openui_v2-multimodal-rag
docker-compose build --no-cache
docker-compose up -d
```

## 🔧 Troubleshooting External Access Issues

### Problem: Streamlit Not Accessible from External IP

If you can access N8N at `http://your-ip:5678` but NOT Streamlit at `http://your-ip:8501`, this indicates a firewall configuration issue.

#### Quick Fixes:

**Option 1: Use the automated fix script (Recommended)**
```bash
./scripts/menu.sh
# Choose option 14 (Fix HTTP Deployment)
```

**Option 2: Manual firewall configuration**
```bash
# For Ubuntu/Debian servers
sudo ufw allow 8501/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 5678/tcp

# Check firewall status
sudo ufw status
```

**Option 3: For Google Cloud Platform users**
```bash
./scripts/menu.sh
# Choose option 15 (Setup GCP Firewall)
```

#### Comprehensive Diagnostics:
```bash
./scripts/menu.sh
# Choose option 16 (Troubleshoot Deployment)
```

This will check:
- Docker and container status
- Port availability and binding
- Firewall configuration
- External connectivity
- Configuration file validity

### Problem: HTTPS Deployment Error

**Error**: `sed: can't read nginx/conf.d/default.conf: No such file or directory`

**Solution**: This occurs when the nginx configuration directory structure is incomplete. The updated deployment script now automatically creates missing directories and files.

```bash
# Ensure nginx directory structure exists
mkdir -p nginx/conf.d

# Run HTTPS deployment again
./scripts/menu.sh
# Choose option 8 (Deploy HTTPS with SSL)
```
