# Claude Code Configuration

This file contains configuration and commands for Claude Code to help with development tasks.

## Project Information
- **Project**: k8s-dapr
- **Type**: Kubernetes + Dapr + Datadog showcase project
- **Location**: /Users/benjamen/Development/github/kubernetes/k8s-dapr
- **Purpose**: Blog article demonstration of microservices with Dapr on Kubernetes

## Architecture
- **NestJS Service**: `comms` - Primary service handling `/greet` POST requests with `{"name": "{name}"}` payload
- **NestJS Service**: `greeter` - Returns `{"message": "Hello, {name} from NestJS greeter!"}`
- **Communication**: HTTP via Dapr SDK service-to-service invocation
- **Observability**: OpenTelemetry → Datadog for distributed tracing
- **Container Registry**:
  - Comms: `public.ecr.aws/f8u4w2p3/node/comms`
  - Greeter: `public.ecr.aws/f8u4w2p3/node/greeter`

## Project Structure
```
.
├── CLAUDE.md
├── kubernetes/
│   ├── eksctl-config.yaml          # Full EKS cluster config
│   ├── cluster-config.yaml         # Simple cluster config
│   ├── namespaces/
│   │   └── dapr-services-namespace.yaml
│   ├── datadog/
│   │   ├── datadog-secret.yaml     # API key: f005b932c81376b5218e16f7f404ce80
│   │   └── datadog-agent.yaml      # Datadog operator config
│   ├── dapr/
│   │   ├── dapr-operator.yaml      # Dapr installation
│   │   └── tracing-config.yaml     # Dapr tracing to Datadog
│   ├── services/
│   │   ├── comms-service.yaml      # NestJS comms service deployment
│   │   └── greeter-service.yaml    # NestJS greeter service deployment
│   └── ingress/
│       └── ingress.yaml            # ALB ingress for external access
└── services/
    ├── comms/                      # NestJS comms service
    │   ├── package.json
    │   ├── tsconfig.json
    │   ├── nest-cli.json
    │   ├── Dockerfile
    │   └── src/
    │       ├── main.ts
    │       ├── tracing.ts          # OpenTelemetry setup
    │       ├── app.module.ts
    │       ├── app.controller.ts
    │       ├── app.service.ts
    │       └── greeter.service.ts
    └── greeter/                    # NestJS greeter service
        ├── package.json
        ├── tsconfig.json
        ├── nest-cli.json
        ├── Dockerfile
        └── src/
            ├── main.ts
            ├── tracing.ts          # OpenTelemetry setup
            ├── app.module.ts
            ├── app.controller.ts
            └── app.service.ts
```

## Deployment Commands

### 1. Create EKS Cluster
```bash
# Create cluster (choose one config)
eksctl create cluster -f kubernetes/cluster-config.yaml
# OR with full config
eksctl create cluster -f kubernetes/eksctl-config.yaml
```

### 2. Install Datadog Operator
```bash
# Install Datadog operator
helm repo add datadog https://helm.datadoghq.com
helm repo update
kubectl create namespace datadog-operator
helm install datadog-operator datadog/datadog-operator -n datadog-operator

# Apply Datadog secret and agent
kubectl apply -f kubernetes/datadog/datadog-secret.yaml
kubectl apply -f kubernetes/datadog/datadog-agent.yaml
```

### 3. Install Dapr
```bash
# Install Dapr CLI (if not installed)
curl -fsSL https://raw.githubusercontent.com/dapr/cli/master/install/install.sh | /bin/bash

# Initialize Dapr on cluster
dapr init -k

# Apply Dapr configuration
kubectl apply -f kubernetes/dapr/tracing-config.yaml
```

### 4. Deploy Services
```bash
# Create namespace
kubectl apply -f kubernetes/namespaces/dapr-services-namespace.yaml

# Deploy services (ensure images are pushed to ECR first)
kubectl apply -f kubernetes/services/greeter-service.yaml
kubectl apply -f kubernetes/services/comms-service.yaml

# Setup ingress (requires AWS Load Balancer Controller)
kubectl apply -f kubernetes/ingress/ingress.yaml
```

### 5. Build and Push Docker Images
```bash
# Build and push NestJS comms service
cd services/comms
docker build -t public.ecr.aws/f8u4w2p3/node/comms:latest .
docker push public.ecr.aws/f8u4w2p3/node/comms:latest

# Build and push NestJS greeter service
cd ../greeter
docker build -t public.ecr.aws/f8u4w2p3/node/greeter:latest .
docker push public.ecr.aws/f8u4w2p3/node/greeter:latest
```

## Development Commands
```bash
# Local development
cd services/comms && npm run start:dev
cd services/greeter && npm run start:dev

# Build services
cd services/comms && npm run build
cd services/greeter && npm run build

# Test the API
curl -X POST "http://localhost:8080/greet" -H "Content-Type: application/json" -d '{"name": "World"}'
curl -X POST "http://YOUR_ALB_URL/greet" -H "Content-Type: application/json" -d '{"name": "World"}'
```

## Monitoring & Observability
- **Datadog Site**: us5.datadoghq.com
- **Cluster Name**: dapr-demo
- **Environment Tag**: demo
- **Project Tag**: k8s-dapr
- **Features Enabled**:
  - APM traces on port 8126
  - Log collection
  - Process monitoring
  - Kubernetes orchestrator explorer

## Key Features
- **Host IP Detection**: Both services detect Kubernetes node IP for Datadog agent
- **Distributed Tracing**: OpenTelemetry spans from Rust → Dapr → Node.js
- **Health Checks**: `/health` endpoints with readiness/liveness probes
- **Auto-scaling**: HPA ready with resource limits
- **Security**: Non-root containers, resource constraints

## Requirements

Context: this is a kubernetes, datadog, and dapr showcase project that I'm going to write a blog article about down the line.

Directory structure:

./kubernetes
./services/comms  # rust code
./services/greeter # node code

* ✅ **Kubernetes cluster**
  * ✅ Created cluster config similar to k8s-datadog-intro reference
  * ✅ Created Datadog operator with API key configuration
  * ✅ Applied Datadog agent configuration with APM, logging, and OTLP
  * ✅ Health check trace filtering configured (partial - greeter working, comms pending)

* ✅ **Dapr**
  * ✅ Installed Dapr operator for service-to-service communication
  * ✅ Configured Dapr tracing to Datadog agent
  * ✅ Applied tracing configuration for distributed observability

* ✅ **Rust service (comms)**
  * ✅ Primary service handling `/greet` POST requests with `{"name": "{name}"}` payload
  * ✅ Service calls greeter service via Dapr HTTP service invocation
  * ✅ OpenTelemetry implemented using patterns from rust-comms reference project
  * ✅ HTTP requests to greeter service use Dapr SDK endpoints
  * ✅ Structured in services/comms subdirectory
  * ✅ Dockerfile implemented using cargo chef for efficient builds
  * ✅ Successfully sends distributed traces to Datadog agent

* ✅ **Node service (greeter)**
  * ✅ Greeter service returns `{"message": "Hello, {name} from Node.js greeter!"}`
  * ✅ Uses Dapr SDK patterns for handling requests (via HTTP endpoints)
  * ✅ OpenTelemetry implemented with automatic instrumentation
  * ✅ Integrated with Datadog for distributed tracing
  * ✅ Built with Docker and deployed successfully
  * ✅ Successfully receives and processes distributed traces from comms service

## ✅ **Working Distributed Tracing Flow**
1. **Request** → Rust comms service (`/greet` endpoint)
2. **Comms service** generates traceparent header and calls Dapr
3. **Dapr** forwards request to Node.js greeter service with trace context
4. **Both services** send correlated traces to Datadog agent
5. **Response** flows back maintaining trace correlation
6. **Result**: Complete end-to-end distributed tracing visible in Datadog APM

## ✅ **New Requirements - COMPLETED**

* ✅ **Convert the Rust comms service to a NestJS Node application**
  * ✅ Complete rewrite from Rust to NestJS TypeScript
  * ✅ OpenTelemetry integration with Datadog exporter
  * ✅ Dapr service invocation to greeter service
  * ✅ Health endpoints and proper error handling
  * ✅ Docker containerization with multi-stage builds

* ✅ **Convert the greeter service to a NestJS service**
  * ✅ Complete rewrite from Express to NestJS TypeScript
  * ✅ OpenTelemetry integration with Datadog exporter
  * ✅ Proper controller/service architecture
  * ✅ Health endpoints and structured responses
  * ✅ Docker containerization with multi-stage builds

* ✅ **Full OpenTelemetry tracing between both applications**
  * ✅ Both services use @opentelemetry/sdk-node with auto-instrumentations
  * ✅ Datadog exporter configured for both services
  * ✅ Trace context propagation between comms → greeter services
  * ✅ Custom spans with detailed attributes
  * ✅ Error tracking and exception recording in spans
  * ✅ Deployment configurations updated for NestJS services

## 🎯 **Ready for Deployment**
All Rust traces have been completely removed and replaced with NestJS services. Both services are ready for building and deployment with full OpenTelemetry distributed tracing.

## Dapr Requirements

* The comms service makes raw Axios requests to dapr endpoints.  I'd like to use the Dapr Client to maek these requests.
* I think if we go with the dapr client, the w3c trace standards are followed by dapr so we need less custom otel tracing.
