#!/bin/bash

# Multimodal RAG System - Script Manager
# Interactive menu to run various setup, deployment, and maintenance scripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Multimodal RAG System - Script Manager        ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║  🔍 Interactive script launcher for setup & maintenance  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

show_menu() {
    echo -e "${CYAN}📋 Select a script to run:${NC}"
    echo ""
    echo -e "${GREEN}🚀 INSTALLATION & SETUP (run these first):${NC}"
    echo "  1) System Prerequisites Check    - Check if Docker/Docker Compose are installed"
    echo "  2) Environment Configuration     - Verify .env file and API keys"
    echo "  3) Dependencies Check           - Verify Python package requirements"
    echo "  4) Full System Setup           - Complete automated setup process"
    echo "  5) Fix Package Versions        - Fix common package version issues"
    echo ""
    echo -e "${YELLOW}🔧 DEPLOYMENT & MAINTENANCE:${NC}"
    echo "  6) Quick Deploy (Interactive)   - Choose HTTP or HTTPS deployment"
    echo "  7) Deploy HTTP Only            - Standard HTTP deployment for testing"
    echo "  8) Deploy HTTPS with SSL       - Production HTTPS with Let's Encrypt"
    echo "  9) Rebuild Containers          - Force rebuild with dependency fixes"
    echo " 10) Validate Deployment         - Check if system is running properly"
    echo ""
    echo -e "${RED}🧹 CLEANUP & TROUBLESHOOTING:${NC}"
    echo " 11) Targeted Cleanup            - Remove only project containers/images"
    echo " 12) Full Cleanup                - Remove all project resources"
    echo " 13) Nuclear Cleanup             - Remove ALL Docker resources (⚠️  WARNING)"
    echo ""
    echo -e "${BLUE}💡 INFORMATION:${NC}"
    echo " 14) Show All Scripts            - List all available scripts"
    echo " 15) Help & Documentation       - Quick help guide"
    echo ""
    echo "  0) Exit"
    echo ""
}

run_script() {
    local script_name="$1"
    local description="$2"
    
    echo ""
    echo -e "${CYAN}🔄 Running: ${description}${NC}"
    echo -e "${YELLOW}Script: ${script_name}${NC}"
    echo "=================================================="
    
    if [ -f "scripts/${script_name}" ]; then
        chmod +x "scripts/${script_name}"
        # Run the script from the project root directory
        ./scripts/"${script_name}"
    else
        echo -e "${RED}❌ Error: Script not found: scripts/${script_name}${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ Script completed: ${description}${NC}"
    echo ""
    read -p "Press Enter to return to menu..."
}

show_scripts() {
    echo ""
    echo -e "${CYAN}📁 Available Scripts in /scripts folder:${NC}"
    echo "=================================================="
    ls -la scripts/ | grep -E "\.(sh|ps1)$" | awk '{print "  " $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}'
    echo ""
    read -p "Press Enter to return to menu..."
}

show_help() {
    echo ""
    echo -e "${CYAN}💡 Quick Help Guide${NC}"
    echo "=================================================="
    echo ""
    echo -e "${GREEN}🚀 First Time Setup:${NC}"
    echo "  1. Run option 1 to check system prerequisites"
    echo "  2. Configure your .env file with API keys"
    echo "  3. Run option 2 to verify environment"
    echo "  4. Run option 4 for full automated setup"
    echo ""
    echo -e "${YELLOW}🔧 Regular Usage:${NC}"
    echo "  - Use option 6 for interactive deployment (choose HTTP/HTTPS)"
    echo "  - Use option 7 for quick HTTP deployment (testing)"
    echo "  - Use option 8 for production HTTPS deployment"
    echo "  - Use option 10 to validate deployment"
    echo "  - Use option 9 if you need to rebuild"
    echo ""
    echo -e "${RED}🧹 Troubleshooting:${NC}"
    echo "  - Use option 11 for safe cleanup"
    echo "  - Use option 12 for complete reset"
    echo "  - Use option 13 only if system is broken"
    echo ""
    echo -e "${BLUE}📖 Documentation:${NC}"
    echo "  - Check README_DOCKER.md for detailed instructions"
    echo "  - All scripts have comments explaining their purpose"
    echo ""
    read -p "Press Enter to return to menu..."
}

# Main loop
while true; do
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Multimodal RAG System - Script Manager        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    show_menu
    
    read -p "Enter your choice (0-15): " choice
    
    case $choice in
        1)
            run_script "check-deps.sh" "System Prerequisites Check"
            ;;
        2)
            run_script "check-env.sh" "Environment Configuration Verification"
            ;;
        3)
            run_script "check-deps.sh" "Dependencies Check"
            ;;
        4)
            run_script "setup.sh" "Full System Setup"
            ;;
        5)
            run_script "fix-versions.sh" "Fix Package Versions"
            ;;
        6)
            run_script "quick-deploy.sh" "Interactive Deployment (HTTP/HTTPS)"
            ;;
        7)
            run_script "deploy.sh" "HTTP Deployment"
            ;;
        8)
            echo ""
            echo -e "${YELLOW}🔒 HTTPS Deployment Setup${NC}"
            echo ""
            read -p "Enter your domain name (e.g., example.com): " domain
            read -p "Enter your email address: " email
            
            if [ -z "$domain" ] || [ -z "$email" ]; then
                echo -e "${RED}❌ Domain and email are required for HTTPS setup${NC}"
                sleep 3
            else
                echo ""
                echo -e "${YELLOW}🔧 Running HTTPS deployment...${NC}"
                chmod +x scripts/deploy-https.sh
                if command -v sudo &> /dev/null; then
                    sudo scripts/deploy-https.sh "$domain" "$email"
                else
                    scripts/deploy-https.sh "$domain" "$email"
                fi
                echo ""
                read -p "Press Enter to return to menu..."
            fi
            ;;
        9)
            run_script "rebuild.sh" "Rebuild Containers"
            ;;
        10)
            run_script "validate.sh" "Validate Deployment"
            ;;
        11)
            run_script "cleanup-targeted.sh" "Targeted Cleanup"
            ;;
        12)
            run_script "cleanup-full.sh" "Full Cleanup"
            ;;
        13)
            echo ""
            echo -e "${RED}⚠️  WARNING: Nuclear cleanup will remove ALL Docker resources!${NC}"
            echo -e "${RED}This includes containers, images, and volumes from other projects.${NC}"
            echo ""
            read -p "Are you sure you want to continue? (yes/no): " confirm
            if [[ $confirm == "yes" ]]; then
                run_script "cleanup-nuclear.sh" "Nuclear Cleanup"
            else
                echo "Nuclear cleanup cancelled."
                sleep 2
            fi
            ;;
        14)
            show_scripts
            ;;
        15)
            show_help
            ;;
        0)
            echo ""
            echo -e "${GREEN}👋 Thank you for using Multimodal RAG Script Manager!${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}❌ Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
