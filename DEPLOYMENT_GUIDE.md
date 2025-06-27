# 🚀 Complete Deployment Guide - Multimodal RAG System

## 🎯 Understanding Your Issues

I've analyzed your multimodal RAG system thoroughly. Here's what I found and fixed:

### Your Current Issues:
1. **N8N Cookie Error**: N8N requires secure cookies when accessed via external IP, but you're using HTTP
2. **Timeout Issues**: Streamlit (8501) and FastAPI (8000) timing out on external IP access
3. **No HTTPS Setup**: Missing SSL/TLS configuration for production deployment

### The System Architecture:
Your RAG system is sophisticated:
- **Cohere Embeddings**: Processes both text and images from PDFs
- **FAISS Vector Database**: Stores and searches embeddings efficiently  
- **Gemini 2.5 Flash**: Generates intelligent responses
- **Streamlit Frontend**: User interface for document upload and querying
- **FastAPI Backend**: REST API for automation and N8N integration
- **N8N Workflow Engine**: Automation and webhook capabilities

## 🔧 Solution: Two Deployment Options

I've created two complete deployment solutions for you:

### Option 1: HTTP (Quick Testing)
- Fixed timeout issues with proper Docker networking
- Disabled N8N secure cookies for HTTP access
- Ready for immediate testing

### Option 2: HTTPS (Production Ready)
- Complete SSL certificate automation with Let's Encrypt
- Nginx reverse proxy with security headers
- Proper subdomain routing for all services
- Production-grade security configuration

## 📋 Quick Start Instructions

### For Testing (HTTP):
```bash
# 1. Navigate to your project
cd /path/to/multimodal_RAG_OpenUI_V2

# 2. Copy environment template
cp .env.example .env

# 3. Edit with your API keys
nano .env

# 4. Deploy quickly
chmod +x scripts/quick-deploy.sh
./scripts/quick-deploy.sh
# Choose option 1 (HTTP)
```

### For Production (HTTPS):
```bash
# 1. Ensure your domain DNS points to your server IP
# 2. Run the deployment helper
chmod +x scripts/quick-deploy.sh
./scripts/quick-deploy.sh
# Choose option 2 (HTTPS)
# Enter your domain and email when prompted
```

## 🌐 DNS Configuration (For HTTPS)

Before HTTPS deployment, configure these DNS A records:

| Record | Points To |
|--------|-----------|
| `your-domain.com` | Your server's external IP |
| `api.your-domain.com` | Your server's external IP |
| `n8n.your-domain.com` | Your server's external IP |

## 🔒 Google Cloud Firewall Setup

```bash
# Allow HTTP traffic
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0

# Allow HTTPS traffic
gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0
```

## 📁 New Files Created

I've added these files to your system:

### HTTPS Configuration:
- `docker-compose-https.yml` - Production Docker setup with SSL
- `nginx/nginx.conf` - Main nginx configuration
- `nginx/conf.d/default.conf` - SSL and routing configuration
- `scripts/deploy-https.sh` - Automated HTTPS deployment
- `scripts/quick-deploy.sh` - Interactive deployment helper
- `.env.example` - Environment template

### Documentation:
- `HTTPS_SETUP.md` - Detailed HTTPS setup guide

## 🎯 Access Points After Deployment

### HTTP Deployment:
- **Streamlit UI**: `http://your-external-ip:8501`
- **API Docs**: `http://your-external-ip:8000/docs`
- **N8N**: `http://your-external-ip:5678`
- **Health Check**: `http://your-external-ip:8000/health`

### HTTPS Deployment:
- **Streamlit UI**: `https://your-domain.com`
- **API Docs**: `https://api.your-domain.com/docs`
- **N8N**: `https://n8n.your-domain.com`
- **Health Check**: `https://api.your-domain.com/health`

## 🔧 What I Fixed

### 1. Docker Networking Issues:
- Added proper container networking
- Fixed port exposure for external access
- Added Streamlit server configuration

### 2. N8N Configuration:
- **HTTP**: Disabled secure cookies for external IP access
- **HTTPS**: Proper SSL configuration with secure cookies enabled
- Fixed webhook URLs and host settings

### 3. Nginx Reverse Proxy:
- SSL termination with Let's Encrypt
- Rate limiting and security headers
- WebSocket support for Streamlit and N8N
- Proper timeouts for large file uploads

### 4. SSL Certificate Management:
- Automated certificate acquisition
- Auto-renewal with cron jobs
- Multi-domain certificates (main + subdomains)

## 🚀 Deployment Commands

### Check Current Status:
```bash
# Check services
docker-compose ps

# Test health
curl http://localhost:8000/health
curl http://localhost:8501/_stcore/health
```

### View Logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f multimodal-rag
docker-compose logs -f n8n
```

### Restart Services:
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart multimodal-rag
```

## 🔍 Troubleshooting

### Common Issues and Solutions:

#### 1. API Key Errors:
```bash
# Check your .env file
cat .env
# Ensure API keys are valid and properly formatted
```

#### 2. Port Conflicts:
```bash
# Check what's using your ports
sudo netstat -tlnp | grep :8501
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :5678
```

#### 3. SSL Certificate Issues:
```bash
# Check certificate status
docker-compose -f docker-compose-https.yml run --rm certbot certificates

# Force renewal
docker-compose -f docker-compose-https.yml run --rm certbot renew --force-renewal
```

#### 4. Memory Issues:
```bash
# Check Docker resources
docker stats
# Increase Docker memory if needed
```

## 📊 Testing Your Deployment

### 1. Upload Test:
1. Access Streamlit UI
2. Go to "Index Documents" tab
3. Upload a PDF file
4. Verify processing completes

### 2. Query Test:
1. Go to "Search" tab
2. Enter a question about your PDF
3. Verify AI response is generated

### 3. API Test:
```bash
# Health check
curl https://api.your-domain.com/health

# Status check
curl https://api.your-domain.com/status

# Upload via API
curl -X POST "https://api.your-domain.com/documents/upload" \
     -H "Content-Type: multipart/form-data" \
     -F "files=@your-document.pdf"
```

### 4. N8N Integration Test:
1. Access N8N interface
2. Create a simple HTTP request node
3. Point to `http://multimodal-rag:8000/health`
4. Execute and verify response

## 🎉 Next Steps

1. **Test the system** with your documents
2. **Create N8N workflows** for automation
3. **Monitor logs** for any issues
4. **Set up backups** for your data volumes
5. **Configure monitoring** and alerting

## 💡 Pro Tips

1. **Use environment variables** for all sensitive configuration
2. **Monitor resource usage** especially during document processing
3. **Regular backups** of Docker volumes
4. **Keep API keys secure** and rotate them periodically
5. **Monitor SSL certificate expiry** (auto-renewal should handle this)

Your multimodal RAG system is now production-ready with both HTTP and HTTPS options! 🚀
