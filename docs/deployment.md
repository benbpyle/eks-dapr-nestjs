# Deployment Documentation

## Deploy Script Overview

The `scripts/deploy.sh` script provides a fully automated deployment of the Kubernetes + Dapr + Datadog showcase environment. It handles everything from EKS cluster creation to service deployment.

## Prerequisites Validation

The script validates all required tools and configurations before starting:

```bash
# Required CLI tools
kubectl    # Kubernetes cluster management
eksctl     # EKS cluster lifecycle
helm       # Kubernetes package manager
docker     # Container builds and pushes
dapr       # Dapr CLI for initialization
aws        # AWS API access

# Required configurations
AWS credentials configured (aws sts get-caller-identity)
Docker daemon running (docker info)
Docker buildx available for multi-arch builds
```

## Deployment Steps

### Step 1: EKS Cluster Creation

**Configuration**: `kubernetes/cluster-config.yaml`
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: dapr-demo
  region: us-west-2
nodeGroups:
  - name: mng-arm
    instanceType: m6g.large  # ARM Graviton2
    minSize: 2
    maxSize: 5
```

**Actions**:
- Creates VPC with public/private subnets
- Provisions managed node group with ARM64 instances
- Installs core EKS add-ons (VPC CNI, CoreDNS, Kube Proxy)
- Associates IAM OIDC provider for service accounts

**Duration**: ~15-20 minutes

### Step 2: Storage Configuration

**EBS CSI Driver Installation**:
```bash
eksctl create addon --cluster dapr-demo --name aws-ebs-csi-driver --region us-west-2
```

**Actions**:
- Installs AWS EBS CSI driver for persistent volumes
- Creates IAM role with required policies
- Sets gp2 as default StorageClass
- Validates driver pods are running

**Required for**: Dapr scheduler persistent volumes

### Step 3: Load Balancer Controller

**AWS Load Balancer Controller**:
```bash
eksctl create iamserviceaccount \
  --cluster=dapr-demo \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess
```

**Actions**:
- Creates IAM service account with ELB permissions
- Installs controller via Helm chart
- Enables ALB ingress for external traffic

### Step 4: Datadog Operator

**Helm Installation**:
```bash
helm repo add datadog https://helm.datadoghq.com
helm install datadog-operator datadog/datadog-operator -n datadog-operator
```

**Configuration**: `kubernetes/datadog/`
- `datadog-secret.yaml`: API key 
- `datadog-agent.yaml`: Agent configuration with OTLP receiver

**Features Enabled**:
- APM traces via OTLP (ports 4317/4318)
- Log collection from all pods
- Infrastructure monitoring
- Kubernetes orchestrator explorer

### Step 5: Dapr Installation

**Control Plane Setup**:
```bash
dapr init -k
```

**Components Installed**:
- `dapr-operator`: Manages Dapr components
- `dapr-sidecar-injector`: Injects sidecars into pods
- `dapr-sentry`: Certificate authority for mTLS
- `dapr-placement`: Actor placement service
- `dapr-scheduler`: Workflow scheduling (3 replicas)

**Configuration**: `kubernetes/dapr/tracing-config.yaml`
```yaml
apiVersion: dapr.io/v1alpha1
kind: Configuration
metadata:
  name: tracing
spec:
  tracing:
    samplingRate: "1"
    otel:
      endpointAddress: "http://datadog-agent.default.svc.cluster.local:4318"
```

### Step 6: Container Image Building

**ECR Repository Creation**:
```bash
aws ecr-public create-repository --region us-east-1 --repository-name node/comms
aws ecr-public create-repository --region us-east-1 --repository-name node/greeter
```

**Multi-Architecture Builds**:
```bash
# Comms service
docker buildx build --platform linux/arm64 \
  -t public.ecr.aws/f8u4w2p3/node/comms:latest --push .

# Greeter service
docker buildx build --platform linux/arm64 \
  -t public.ecr.aws/f8u4w2p3/node/greeter:latest --push .
```

**Build Process**:
- Multi-stage Dockerfiles for efficient builds
- ARM64 targeting for Graviton2 instances
- Automatic push to ECR Public registry
- Layer caching for faster subsequent builds

### Step 7: Service Deployment

**Kubernetes Manifests**:
```bash
kubectl apply -f kubernetes/namespaces/dapr-services-namespace.yaml
kubectl apply -f kubernetes/services/greeter-service.yaml
kubectl apply -f kubernetes/services/comms-service.yaml
kubectl apply -f kubernetes/ingress/ingress.yaml
```

**Deployment Features**:
- 2 replicas per service for high availability
- Dapr sidecar injection via annotations
- Health checks (readiness/liveness probes)
- Resource limits and requests
- Security contexts (non-root, read-only)

## Script Features

### Idempotency
The script can be run multiple times safely:
- Skips existing clusters
- Checks for existing resources before creation
- Updates configurations if needed
- Graceful handling of "already exists" errors

### Error Handling
```bash
set -e  # Exit on any error
trap cleanup EXIT  # Cleanup on script exit

# Validation functions
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed"
        exit 1
    fi
}
```

### Progress Tracking
- Colored output for different message types
- Detailed status updates for long-running operations
- Timeout handling for deployment waits
- Final summary with next steps

### Platform Compatibility
- Detects Docker daemon availability
- Handles ARM64 vs AMD64 architecture
- macOS-specific helper messages
- Cross-platform shell compatibility

## Deployment Verification

### Service Health Checks
```bash
# Check all pods are running
kubectl get pods -n dapr-services

# Verify Dapr sidecars
kubectl get pods -n dapr-services -o jsonpath='{.items[*].spec.containers[*].name}'

# Test service connectivity
kubectl port-forward -n dapr-services svc/comms-service 8080:80
curl -X POST "http://localhost:8080/greet" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test"}'
```

### Infrastructure Validation
```bash
# EKS cluster status
eksctl get cluster --name dapr-demo

# Node readiness
kubectl get nodes

# Add-on status
eksctl get addons --cluster dapr-demo

# Dapr control plane
dapr status -k
```

## Troubleshooting Common Issues

### Docker Daemon Not Running
```bash
Error: Cannot connect to the Docker daemon at unix:///var/run/docker.sock
Solution: Start Docker Desktop or ensure Docker service is running
```

### ECR Authentication Failure
```bash
Error: no basic auth credentials
Solution: Re-run ECR login command
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
```

### Insufficient AWS Permissions
```bash
Error: User is not authorized to perform: eks:CreateCluster
Required IAM policies:
- AmazonEKSClusterPolicy
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly
```

### Node Scheduling Issues
```bash
# Check node status
kubectl get nodes

# If nodes show SchedulingDisabled
kubectl uncordon <node-name>
```

### Dapr Scheduler Not Ready
```bash
# Check scheduler pods
kubectl get pods -n dapr-system -l app=dapr-scheduler-server

# Check storage class
kubectl get storageclass

# Verify EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi
```

## Cleanup and Deletion

### Full Cluster Deletion
```bash
eksctl delete cluster --name dapr-demo --region us-west-2
```

**What gets deleted**:
- EKS cluster and node groups
- VPC and associated networking
- Load balancers and target groups
- IAM roles and policies (cluster-related)
- EBS volumes and snapshots

**Duration**: ~10-15 minutes

### Partial Cleanup Options

**Delete Services Only**:
```bash
kubectl delete namespace dapr-services
kubectl delete namespace datadog-operator
```

**Delete Specific Components**:
```bash
# Remove Dapr
dapr uninstall -k

# Remove Datadog Operator
helm uninstall datadog-operator -n datadog-operator

# Remove Load Balancer Controller
helm uninstall aws-load-balancer-controller -n kube-system
```

### Manual Cleanup Requirements

**ECR Repositories** (not auto-deleted):
```bash
aws ecr-public delete-repository --region us-east-1 --repository-name node/comms --force
aws ecr-public delete-repository --region us-east-1 --repository-name node/greeter --force
```

**CloudFormation Stacks** (check for stragglers):
```bash
aws cloudformation list-stacks --region us-west-2 | grep dapr-demo
```

**IAM Roles** (cleanup if needed):
```bash
aws iam list-roles | grep dapr-demo
```

## Performance Optimization

### Faster Deployments
- Use existing cluster: Skip Step 1
- Pre-built images: Skip Step 6
- Local registry: Use minikube registry
- Parallel operations: Multiple terminals

### Resource Efficiency
- Smaller instance types for development
- Reduced replica counts
- Spot instances for cost savings
- Regional proximity for latency

### Development Workflow
```bash
# Quick redeploy after code changes
cd services/comms
docker build -t public.ecr.aws/f8u4w2p3/node/comms:latest .
docker push public.ecr.aws/f8u4w2p3/node/comms:latest
kubectl rollout restart deployment/comms -n dapr-services
```

## Monitoring Deployment Success

### Datadog Verification
1. Navigate to us5.datadoghq.com
2. Check Infrastructure → Kubernetes
3. Verify services appear in Service Map
4. Confirm traces in APM → Traces

### End-to-End Testing
```bash
# Get ALB URL
ALB_URL=$(kubectl get ingress -n dapr-services -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Test API
curl -X POST "http://$ALB_URL/greet" \
  -H "Content-Type: application/json" \
  -d '{"name": "Production"}'

# Expected response
{"message":"Hello, Production from NestJS greeter!"}
```

### Health Dashboard
Monitor these key metrics:
- Cluster node status: All Ready
- Pod status: All Running
- Service endpoints: All healthy
- Ingress status: ALB provisioned
- Datadog agent: Sending metrics

The deployment script provides a robust, production-ready environment suitable for development, testing, and demonstration purposes.
