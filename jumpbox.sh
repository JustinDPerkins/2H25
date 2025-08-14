#!/bin/bash

# Boring Paper Co TechDay Jumpbox Setup Script
# This script will be run automatically when the EC2 instance starts

set -e

echo "🚀 Starting Boring Paper Co TechDay Jumpbox setup..."

# Update system packages
echo "📦 Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install essential packages
echo "📦 Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
echo "🐳 Installing Docker..."
# Remove any old Docker versions
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ssm-user to docker group (only if user exists)
if id "ssm-user" &>/dev/null; then
    usermod -a -G docker ssm-user
else
    echo "⚠️ ssm-user not found yet, will be added to docker group when user is created"
    # Create a script to run later when ssm-user exists
    cat > /usr/local/bin/add-ssm-user-to-docker.sh << 'EOF'
#!/bin/bash
# Wait for ssm-user to exist and add to docker group
while ! id "ssm-user" &>/dev/null; do
    sleep 5
done
usermod -a -G docker ssm-user
echo "✅ Added ssm-user to docker group"
EOF
    chmod +x /usr/local/bin/add-ssm-user-to-docker.sh
    # Run this script in background
    nohup /usr/local/bin/add-ssm-user-to-docker.sh > /var/log/add-ssm-user.log 2>&1 &
fi

# Install kubectl
echo "⚙️ Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
echo "🎯 Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y
apt-get install -y helm

# Set up environment and aliases
echo "🔧 Setting up environment and aliases..."

# Create ssm-user home directory if it doesn't exist
if [ ! -d "/home/ssm-user" ]; then
    echo "📁 Creating ssm-user home directory..."
    mkdir -p /home/ssm-user
    chown 1000:1000 /home/ssm-user  # Use typical UID/GID for ssm-user
fi

# Create .bashrc if it doesn't exist
if [ ! -f "/home/ssm-user/.bashrc" ]; then
    touch /home/ssm-user/.bashrc
    chown 1000:1000 /home/ssm-user/.bashrc
fi

cat >> /home/ssm-user/.bashrc << 'EOF'

# Boring Paper Co TechDay Lab Aliases
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgi='kubectl get ingress'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdi='kubectl describe ingress'
alias kl='kubectl logs'
alias kex='kubectl exec -it'

# Docker aliases
alias d='docker'
alias dps='docker ps'
alias dimg='docker images'
alias dex='docker exec -it'

# Quick status check
alias status='echo "=== PODS ===" && kubectl get pods -A && echo "=== SERVICES ===" && kubectl get svc -A && echo "=== INGRESS ===" && kubectl get ingress -A'

# Boring Paper Co specific
alias bpc-status='kubectl get all -n boring-paper-co'
alias bpc-logs='kubectl logs -f -n boring-paper-co -l app=ui'
alias bpc-pods='kubectl get pods -n boring-paper-co'

# Colorize kubectl output
export KUBECOLOR=1
EOF

# Set proper ownership
chown -R 1000:1000 /home/ssm-user/.bashrc

# Create useful directories
echo "📁 Creating useful directories..."
mkdir -p /home/ssm-user/2H25
mkdir -p /home/ssm-user/workspace
chown -R 1000:1000 /home/ssm-user/2H25
chown -R 1000:1000 /home/ssm-user/workspace

# Clone the 2H25 repo
echo "📥 Cloning 2H25 repository..."
cd /home/ssm-user/2H25
git clone https://github.com/JustinDPerkins/2H25.git
cd 2H25/aws/k8s
chmod +x *.sh

# Create a quick start guide
cat > /home/ssm-user/QUICKSTART.md << 'EOF'
# 🚀 Boring Paper Co TechDay Lab - Quick Start

## 🎯 What's Installed
- ✅ Docker (with ssm-user in docker group)
- ✅ kubectl
- ✅ Helm
- ✅ Git
- ✅ 2H25 repository cloned

## 🚀 Quick Commands
```bash
# Check what's installed
docker --version
kubectl version --client
helm version
git --version

# Start the lab!
cd 2H25/aws/k8s
./1_build-and-push.sh
./2_update-image-refs.sh
./3_deploy.sh
```

## 🔧 Useful Aliases
- `k` = `kubectl`
- `kgp` = `kubectl get pods`
- `kgs` = `kubectl get services`
- `bpc-status` = check Boring Paper Co status
- `status` = overall cluster status

## 📁 Directory Structure
- `/home/ssm-user/2H25/` - Lab files
- `/home/ssm-user/workspace/` - Your work area

## 🆘 Need Help?
- Check the TechDay.md guide in the repo
- Use `kubectl get events -A` to see what's happening
- Check logs with `kubectl logs -f <pod-name> -n <namespace>`
EOF

chown 1000:1000 /home/ssm-user/QUICKSTART.md

# Final system setup
echo "🔧 Final system setup..."

# Set timezone (adjust as needed)
timedatectl set-timezone UTC

# Enable and start services
systemctl enable docker
systemctl start docker

# Create a welcome message
cat > /etc/update-motd.d/99-boring-paper-co << 'EOF'
#!/bin/bash
echo ""
echo "🚀 Welcome to Boring Paper Co TechDay Lab Jumpbox!"
echo "📚 Check /home/ssm-user/QUICKSTART.md for getting started"
echo "🔧 All tools are installed and ready to use"
echo "📁 Your workspace: /home/ssm-user/2H25"
echo ""
EOF

chmod +x /etc/update-motd.d/99-boring-paper-co

# Clean up
echo "🧹 Cleaning up..."
apt-get autoremove -y
apt-get autoclean

# Final message
echo ""
echo "🎉 Boring Paper Co TechDay Jumpbox setup complete!"
echo ""
echo "✅ What's installed:"
echo "   🐳 Docker (with ssm-user access)"
echo "   ⚙️ kubectl"
echo "   🎯 Helm"
echo "   📚 Git"
echo "   📁 2H25 repository cloned"
echo ""
echo "📚 Next steps:"
echo "   1. Connect via SSM as 'ssm-user'"
echo "   2. Check: /home/ssm-user/QUICKSTART.md"
echo "   3. Start the lab!"
echo ""
echo "🔧 Useful commands:"
echo "   docker --version"
echo "   kubectl version --client"
echo "   helm version"
echo "   git --version"
echo ""

# Reboot to ensure all services are properly started
echo "🔄 Rebooting in 10 seconds to ensure all services are properly started..."
sleep 10
reboot