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
    jq \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    tree \
    vim \
    nano

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

# Add ubuntu user to docker group
usermod -a -G docker ubuntu

# Install AWS CLI v2
echo "☁️ Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

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

# Install kubectx and kubens for easier context switching
echo "🔄 Installing kubectx and kubens..."
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install kubectl plugins
echo "🔌 Installing kubectl plugins..."
mkdir -p /home/ubuntu/.kube/plugins
cd /home/ubuntu/.kube/plugins

# Install krew (kubectl plugin manager)
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz"
tar zxvf krew-linux_amd64.tar.gz
./krew-linux_amd64 install krew
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /home/ubuntu/.bashrc

# Install useful kubectl plugins via krew
export PATH="${KREW_ROOT:-/home/ubuntu/.krew}/bin:$PATH"
kubectl krew install access-matrix
kubectl krew install neat
kubectl krew install tree
kubectl krew install view-secret

# Install additional useful tools
echo "🛠️ Installing additional tools..."

# Install yq for YAML processing
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq

# Install stern for log tailing
wget https://github.com/stern/stern/releases/latest/download/stern_linux_amd64.tar.gz
tar -xzf stern_linux_amd64.tar.gz
mv stern /usr/local/bin/
rm stern_linux_amd64.tar.gz

# Install k9s for terminal UI
wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz

# Install eksctl
echo "☸️ Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Set up environment and aliases
echo "🔧 Setting up environment and aliases..."
cat >> /home/ubuntu/.bashrc << 'EOF'

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
alias kctx='kubectx'
alias kns='kubens'

# Docker aliases
alias d='docker'
alias dps='docker ps'
alias dimg='docker images'
alias dex='docker exec -it'

# AWS aliases
alias aws-account='aws sts get-caller-identity --query Account --output text'
alias aws-region='aws configure get region'

# Quick status check
alias status='echo "=== PODS ===" && kubectl get pods -A && echo "=== SERVICES ===" && kubectl get svc -A && echo "=== INGRESS ===" && kubectl get ingress -A'

# Boring Paper Co specific
alias bpc-status='kubectl get all -n boring-paper-co'
alias bpc-logs='kubectl logs -f -n boring-paper-co -l app=ui'
alias bpc-pods='kubectl get pods -n boring-paper-co'

# Colorize kubectl output
export KUBECOLOR=1

# Set default namespace
export KUBECTX_IGNORE_FUSE=1
EOF

# Set proper ownership
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chown -R ubuntu:ubuntu /home/ubuntu/.bashrc

# Create useful directories
echo "📁 Creating useful directories..."
mkdir -p /home/ubuntu/2H25
mkdir -p /home/ubuntu/workspace
chown -R ubuntu:ubuntu /home/ubuntu/2H25
chown -R ubuntu:ubuntu /home/ubuntu/workspace

# Download the 2H25 scripts
echo "📥 Downloading 2H25 scripts..."
cd /home/ubuntu/2H25

# Create a simple script to clone the repo
cat > /home/ubuntu/2H25/setup-repo.sh << 'EOF'
#!/bin/bash
echo "🚀 Setting up Boring Paper Co repository..."
if [ ! -d "2H25" ]; then
    git clone https://github.com/JustinDPerkins/2H25.git
    cd 2H25/aws/k8s
    chmod +x *.sh
    echo "✅ Repository cloned and scripts made executable!"
    echo "📁 You can now run:"
    echo "   cd 2H25/aws/k8s"
    echo "   ./1_build-and-push.sh"
else
    echo "✅ Repository already exists!"
fi
EOF

chmod +x /home/ubuntu/2H25/setup-repo.sh
chown ubuntu:ubuntu /home/ubuntu/2H25/setup-repo.sh

# Create a quick start guide
cat > /home/ubuntu/QUICKSTART.md << 'EOF'
# 🚀 Boring Paper Co TechDay Lab - Quick Start

## 🎯 What's Installed
- ✅ Docker (with ubuntu user in docker group)
- ✅ AWS CLI v2
- ✅ kubectl + useful plugins
- ✅ Helm
- ✅ eksctl
- ✅ kubectx/kubens
- ✅ k9s (terminal UI)
- ✅ stern (log tailing)
- ✅ yq (YAML processing)

## 🚀 Quick Commands
```bash
# Check what's installed
docker --version
aws --version
kubectl version --client
helm version

# Set up your AWS credentials
aws configure

# Connect to your EKS cluster
aws eks --region <region> update-kubeconfig --name <cluster-name>

# Set up the 2H25 repo
cd 2H25
./setup-repo.sh

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
- `/home/ubuntu/2H25/` - Lab files
- `/home/ubuntu/workspace/` - Your work area

## 🆘 Need Help?
- Check the TechDay.md guide in the repo
- Use `kubectl get events -A` to see what's happening
- Check logs with `kubectl logs -f <pod-name> -n <namespace>`
EOF

chown ubuntu:ubuntu /home/ubuntu/QUICKSTART.md

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
echo "📚 Check /home/ubuntu/QUICKSTART.md for getting started"
echo "🔧 All tools are installed and ready to use"
echo "📁 Your workspace: /home/ubuntu/2H25"
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
echo "   🐳 Docker (with ubuntu user access)"
echo "   ☁️ AWS CLI v2"
echo "   ⚙️ kubectl + plugins"
echo "   🎯 Helm"
echo "   ☸️ eksctl"
echo "   🔌 kubectx/kubens"
echo "   🖥️ k9s (terminal UI)"
echo "   📝 stern (log tailing)"
echo "   📄 yq (YAML processing)"
echo ""
echo "📚 Next steps:"
echo "   1. SSH into this instance as 'ubuntu'"
echo "   2. Run: aws configure"
echo "   3. Check: /home/ubuntu/QUICKSTART.md"
echo "   4. Start the lab!"
echo ""
echo "🔧 Useful commands:"
echo "   docker --version"
echo "   aws --version"
echo "   kubectl version --client"
echo "   helm version"
echo ""

# Reboot to ensure all services are properly started
echo "🔄 Rebooting in 10 seconds to ensure all services are properly started..."
sleep 10
reboot
