# 🚀 2H25 TechDay Lab

Welcome to the 2H25 TechDay Lab! In this hands-on session, you'll deploy a multi-service application and then configure AI protection using Trend Micro's security services.

## 🎯 Lab Objectives

By the end of this lab, you will:
1. ✅ Deploy a multi-service application to EKS
2. 🔒 Deploy Trend Micro Container Security Helm chart for Cluster Protection
2. 🔒 Configure Trend Micro AI Guard for Content Protection
3. 🛡️ Enable Trend Micro File Scanner for Malware Detection
4. 🧪 Test the security protection in action

## 📋 Prerequisites

Your jumpbox should have:
- ✅ AWS CLI configured with appropriate permissions using **us-west-2**
- **us-west-2 for Region in AWS**
- ✅ `helm` installed and configured for chart deployments
- ✅ `kubectl` installed and configured for EKS
- ✅ `docker` installed and running

---
## 🚀 Phase 1: Initial Deployment (No Trend Protection)

### Step 1: Build and Push Images
```bash
# Build all Docker images and push to ECR
./1_build-and-push.sh
```

**What this does:**
- Builds Docker images for all services
- Creates ECR repositories if they don't exist
- Pushes images to your AWS account's ECR

---

### Step 2: Update Image References
```bash
# Update deployment files with correct ECR image URLs
./2_update-image-refs.sh
```

**What this does:**
- Updates all deployment YAML files with your ECR image references
- Replaces placeholder values with actual AWS account and region

---

### Step 3: Deploy to EKS
```bash
# Deploy the application to your EKS cluster
./3_deploy.sh
```

**What this does:**
- Installs NGINX Ingress Controller
- Deploys all application services
- Creates necessary Kubernetes resources

---

### Step 4: Verify Deployment
```bash
# Check that all pods are running
kubectl get pods -n <namespace-here>

# Check services
kubectl get svc -n <namespace-here>

# Get the external IP/URL
kubectl get ingress -n <namespace-here>
```

---

## 🔒 Phase 2: Adding Trend Micro Protection

### 📋 Prerequisites

You'll need:
1. **API Key** from Trend Vision One that are properly scoped
2. **Region** for the V1FS SDK Service

### Step 1: Base64 Encode the Credentials

```bash
# Encode your API key
echo -n "your-actual-api-key-here" | base64

# Encode your region
echo -n "region-here" | base64
```

**Example:**
```bash
$ echo -n "abc123immasecretdef456" | base64
YWJjMTIzZGVmNDU2

$ echo -n "northpole" | base64
dXMtMQ==
```

### Step 3: Update the Secret Configuration

Edit `secret.yaml` and replace the placeholder values:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: boring-paper-co
type: Opaque
data:
  API_KEY: "YWJjMTIzZGVmNDU2"  # Your base64 encoded API key will be long
  REGION: "dXMtMQ=="            # Your base64 encoded region
```

---

### Step 4: Rebuild and Redeploy

```bash
# Rebuild images with updated configuration
./1_build-and-push.sh

```

### Step 5: Rollout New Images

```bash
# Restart all services to pick up new configuration
kubectl rollout restart deployment/ui-deployment -n <namespace-here>
kubectl rollout restart deployment/sdk-deployment -n <namespace-here>
kubectl rollout restart deployment/aichat-deployment -n <namespace-here>
kubectl rollout restart deployment/containerxdr-deployment -n <namespace-here>

# Monitor the rollout
kubectl rollout status deployment/ui-deployment -n <namespace-here>
kubectl rollout status deployment/sdk-deployment -n <namespace-here>
kubectl rollout status deployment/aichat-deployment -n <namespace-here>
kubectl rollout status deployment/containerxdr-deployment -n <namespace-here>
```

## 🧪 Phase 3: Testing Your Protection

### Test 1: AI Guard Protection
1. Open the application in your browser
2. Navigate to the chat interface
3. Try sending a potentially harmful prompt
4. Verify it gets blocked by Trend Vision One

### Test 2: File Scanner Protection
1. Upload a test file (you can use EICAR test file)
2. Verify the file gets scanned
3. Check the scan results in the response

### Test 3: Check Logs
```bash
# Check AI Guard logs
kubectl logs -f deployment/aichat-deployment -n <namespace-here>

# Check SDK scanner logs
kubectl logs -f deployment/sdk-deployment -n <namespace-here>
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Images Not Building
```bash
# Check Docker is running
docker ps

# Verify AWS credentials
aws sts get-caller-identity
```

#### 2. Deployment Failing
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace-here>

# Check events
kubectl get events -n <namespace-here> --sort-by='.lastTimestamp'
```

#### 3. Protection Not Working
```bash
# Verify secrets are loaded
kubectl get secret app-secrets -n <namespace-here> -o yaml

# Check environment variables in pods
kubectl exec -it <pod-name> -n <namespace-here> -- env | grep -E "(API_KEY|REGION)"
```

#### 4. ECR Access Issues
```bash
# Re-login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
```

## 📚 Additional Resources

- **Trend Micro Vision One**: [Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-introduction-part-trend-vision-one)
- **EKS Best Practices**: [AWS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/best-practices.html)
- **Kubernetes Commands**: [Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## 🎉 Lab Completion

Congratulations! You've successfully:
- ✅ Deployed a multi-service application to EKS
- 🔒 Configured Trend Micro AI Guard for content protection
- 🛡️ Enabled Trend Micro File Scanner for malware detection
- 🧪 Tested the security protection in action

You now have hands-on experience with:
- Container orchestration with Kubernetes
- Cloud-native application deployment
- AI-powered security protection
- File scanning and malware detection

## 🚀 Next Steps

Consider exploring:
- Scaling your application with HPA (Horizontal Pod Autoscaler)
- Implementing monitoring with Prometheus and Grafana
- Adding more security layers (network policies, RBAC)
- Building CI/CD pipelines for automated deployments

---

**Lab Duration**: 1-2 hours  
**Difficulty**: Intermediate  
**Cloud Provider**: AWS EKS  
**Security Focus**: AI Guard + File Scanning
