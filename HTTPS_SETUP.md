# SSL Certificate Setup and HTTPS Deployment Guide

This guide will help you set up HTTPS with Let's Encrypt SSL certificates for your multimodal RAG system.

## Prerequisites

1. **Domain**: You own a domain name (e.g., `your-domain.com`)
2. **DNS**: Point these subdomains to your server's external IP:
   - `your-domain.com` → Your server IP
   - `api.your-domain.com` → Your server IP  
   - `n8n.your-domain.com` → Your server IP
3. **Google Cloud**: Firewall rules allowing ports 80 and 443

## Step 1: Configure DNS Records

In your domain registrar's DNS settings, add these A records:

```
Type: A    Name: @              Value: YOUR_SERVER_EXTERNAL_IP
Type: A    Name: api            Value: YOUR_SERVER_EXTERNAL_IP
Type: A    Name: n8n            Value: YOUR_SERVER_EXTERNAL_IP
```

## Step 2: Configure Environment Variables

Create a `.env` file with your settings:

```bash
# API Keys (required)
COHERE_API_KEY=your_cohere_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash-preview-04-17

# N8N Configuration
N8N_USER=admin
N8N_PASSWORD=your_secure_password_here
N8N_ENCRYPTION_KEY=your_32_character_encryption_key_here
N8N_DOMAIN=n8n.your-domain.com

# Domain Configuration
DOMAIN=your-domain.com
EMAIL=your-email@example.com
```

## Step 3: Update Domain Configuration

Replace `your-domain.com` in these files with your actual domain:

1. **docker-compose-https.yml**: Update the certbot command
2. **nginx/conf.d/default.conf**: Replace all instances of `your-domain.com`

## Step 4: Configure Google Cloud Firewall

```bash
# Allow HTTP traffic
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP traffic"

# Allow HTTPS traffic  
gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTPS traffic"
```

## Step 5: Initial SSL Certificate Setup

Run this setup script to get your initial certificates:

```bash
#!/bin/bash

# Set your domain and email
DOMAIN="your-domain.com"
EMAIL="your-email@example.com"

# Update nginx config with your domain
sed -i "s/your-domain.com/$DOMAIN/g" nginx/conf.d/default.conf
sed -i "s/your-email@example.com/$EMAIL/g" docker-compose-https.yml

# Create temporary nginx config for initial certificate
mkdir -p nginx/ssl
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

# Start nginx for certificate challenge
docker-compose -f docker-compose-https.yml up -d nginx

# Wait for nginx to start
sleep 10

# Get certificates
docker-compose -f docker-compose-https.yml run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d api.$DOMAIN \
    -d n8n.$DOMAIN

# Replace with main config
rm nginx/conf.d/initial.conf
mv nginx/conf.d/default.conf.backup nginx/conf.d/default.conf 2>/dev/null || true

# Restart with full configuration
docker-compose -f docker-compose-https.yml down
docker-compose -f docker-compose-https.yml up -d
```

## Step 6: Deploy the Full System

```bash
# Deploy with HTTPS
docker-compose -f docker-compose-https.yml up -d

# Check status
docker-compose -f docker-compose-https.yml ps

# View logs
docker-compose -f docker-compose-https.yml logs -f
```

## Step 7: Verify Deployment

Check these URLs in your browser:

- **Streamlit UI**: `https://your-domain.com`
- **API Docs**: `https://api.your-domain.com/docs`
- **N8N Interface**: `https://n8n.your-domain.com`
- **API Health**: `https://api.your-domain.com/health`

## Automated Certificate Renewal

Add this to your crontab for automatic certificate renewal:

```bash
# Edit crontab
crontab -e

# Add this line to renew certificates at 2 AM daily
0 2 * * * cd /path/to/your/project && docker-compose -f docker-compose-https.yml run --rm certbot renew && docker-compose -f docker-compose-https.yml exec nginx nginx -s reload
```

## Troubleshooting

### Certificate Issues
```bash
# Check certificate status
docker-compose -f docker-compose-https.yml run --rm certbot certificates

# Manual certificate renewal
docker-compose -f docker-compose-https.yml run --rm certbot renew --force-renewal
```

### N8N Cookie Issues
If you still get cookie errors:
1. Clear your browser cache
2. Ensure you're accessing via `https://n8n.your-domain.com`
3. Check N8N environment variables in docker-compose

### Port Issues on Google Cloud
```bash
# Check if ports are open
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Check firewall status
sudo ufw status
```

### SSL Configuration Test
```bash
# Test SSL configuration
curl -I https://your-domain.com
curl -I https://api.your-domain.com
curl -I https://n8n.your-domain.com
```

## Security Best Practices

1. **Strong Passwords**: Use complex passwords for N8N
2. **Firewall**: Only open necessary ports (80, 443)
3. **Updates**: Regularly update Docker images
4. **Monitoring**: Set up log monitoring
5. **Backups**: Regular backups of volumes

## Quick Deployment Script

Save this as `deploy-https.sh`:

```bash
#!/bin/bash
set -e

# Configuration
DOMAIN="${1:-your-domain.com}"
EMAIL="${2:-your-email@example.com}"

echo "🚀 Deploying HTTPS setup for domain: $DOMAIN"

# Update configurations
sed -i "s/your-domain.com/$DOMAIN/g" nginx/conf.d/default.conf
sed -i "s/your-email@example.com/$EMAIL/g" docker-compose-https.yml

# Deploy
docker-compose -f docker-compose-https.yml up -d

echo "✅ Deployment complete!"
echo "🌐 Access your services at:"
echo "   - Streamlit: https://$DOMAIN"
echo "   - API: https://api.$DOMAIN/docs"
echo "   - N8N: https://n8n.$DOMAIN"
```

Run with:
```bash
chmod +x deploy-https.sh
./deploy-https.sh your-domain.com your-email@example.com
```
