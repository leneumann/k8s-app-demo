# MyApi - Local Kubernetes Development Demo

A complete local development setup featuring a .NET 8 Web API, local Docker registry, and Kubernetes deployment.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │───▶│ Local Registry  │───▶│   Kubernetes    │
│   Machine       │    │ localhost:5000  │    │    Cluster      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                               ┌─────────────────┐
                                               │   MyApi Pods    │
                                               │   (3 replicas)  │
                                               └─────────────────┘
```

## 📁 Project Structure

```
project/
├── src/                    # .NET 8 Web API source code
│   ├── Controllers/        # API controllers
│   ├── Models/            # Data models
│   ├── Program.cs         # Application entry point
│   ├── MyApi.csproj       # Project file
│   └── appsettings.json   # Configuration
├── Dockerfile             # Container definition
├── k8s/                   # Kubernetes manifests
│   ├── deployment.yaml    # Pod deployment (2-10 replicas)
│   ├── service.yaml       # Service definitions
│   ├── configmap.yaml     # Configuration
│   ├── hpa.yaml           # Horizontal Pod Autoscaler
│   └── ingress.yaml       # Ingress controller
├── scripts/               # Automation scripts
│   ├── registry-start.sh  # Start local registry
│   ├── registry-stop.sh   # Stop local registry
│   ├── build.sh          # Build and push image
│   ├── deploy.sh         # Deploy to K8s
│   ├── logs.sh           # View application logs
│   ├── cleanup.sh        # Clean up resources
│   └── setup-k8s.sh      # Setup K8s environment
├── docker-compose.yml     # Local registry definition
├── Makefile              # Development workflow commands
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Local Kubernetes cluster:
  - [Docker Desktop](https://docs.docker.com/desktop/kubernetes/) (recommended)
  - [minikube](https://minikube.sigs.k8s.io/docs/start/)
  - [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)

### 1. Complete Setup (Recommended)

```bash
# Clone and navigate to project
cd k8s-app-demo

# Run complete development workflow
make dev
```

This single command will:
- ✅ Setup Kubernetes environment
- ✅ Start local Docker registry
- ✅ Build and push Docker image
- ✅ Deploy to Kubernetes
- ✅ Show deployment status

### 2. Step-by-Step Setup

```bash
# 1. Setup environment
make setup

# 2. Build application
make build

# 3. Deploy to Kubernetes
make deploy

# 4. Check status
make status
```

## 🔧 Development Workflow

### Available Make Commands

```bash
make help          # Show all available commands
make setup          # Setup local environment (includes metrics server)
make fix-metrics    # Fix metrics server for HPA (if needed)
make build          # Build and push Docker image
make deploy         # Deploy to Kubernetes
make redeploy       # Build and deploy in one command
make logs           # Show application logs
make logs-follow    # Follow application logs
make status         # Show deployment status
make test           # Test the deployed application
make load-test      # Generate load to trigger auto-scaling
make load-test-long # Generate load for 5 minutes
make load-test-heavy # Generate heavy load (more concurrent)
make clean          # Clean up all resources
make dev            # Complete development workflow
```

### Docker Commands

```bash
make docker-build   # Build image locally
make docker-run     # Run container locally
make docker-stop    # Stop local container
```

### Registry Commands

```bash
make registry-start # Start local registry only
make registry-stop  # Stop local registry only
make registry-ui    # Show registry catalog
```

### Kubernetes Commands

```bash
make k8s-pods       # Show all pods
make k8s-services   # Show all services
make k8s-hpa        # Show horizontal pod autoscaler status
make k8s-watch-scaling # Watch HPA and pod scaling in real-time
make k8s-logs       # Show logs from all pods
make k8s-describe   # Describe deployment
make k8s-port-forward # Port forward to pod
```

## 🌐 API Endpoints

Once deployed, the API is available at:

- **NodePort**: `http://localhost:30080`
- **Minikube**: `minikube service myapi-service --url`

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Root endpoint with API info |
| GET | `/health` | Health check endpoint |
| GET | `/api/users` | Get all users |
| POST | `/api/users` | Create new user |
| GET | `/swagger` | Swagger UI documentation |

### Example Usage

```bash
# Health check
curl http://localhost:30080/health

# Get users
curl http://localhost:30080/api/users

# Create user
curl -X POST http://localhost:30080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# Test using make
make test
```

## ⚡ Auto-Scaling

The deployment includes Horizontal Pod Autoscaler (HPA) that automatically scales pods based on CPU and memory usage:

### Auto-Scaling Configuration

- **Min replicas**: 2 pods
- **Max replicas**: 10 pods  
- **CPU target**: 70% utilization
- **Memory target**: 80% utilization

### Testing Auto-Scaling

```bash
# Generate load to trigger scaling
make load-test

# Watch scaling in real-time (in another terminal)
make k8s-watch-scaling

# Or use the simpler HPA status
make k8s-hpa

# Check current pod count
make k8s-pods

# Different load test options
make load-test        # 2 minutes, 10 concurrent
make load-test-long   # 5 minutes, 15 concurrent  
make load-test-heavy  # 3 minutes, 20 concurrent
```

### Scaling Behavior

- **Scale Up**: Up to 100% increase or 2 pods every 15-60 seconds
- **Scale Down**: Up to 50% decrease every 60 seconds with 5-minute stabilization
- **Metrics**: Based on CPU (70%) and memory (80%) utilization

### HPA Status Commands

```bash
# Show HPA status
make k8s-hpa
kubectl get hpa myapi-hpa

# Detailed HPA information
kubectl describe hpa myapi-hpa

# Watch scaling events
kubectl get events --sort-by='.lastTimestamp' | grep HorizontalPodAutoscaler
```

## 🔍 Monitoring & Debugging

### View Logs

```bash
# View logs from all pods
make logs

# Follow logs in real-time
make logs-follow

# View logs using kubectl
kubectl logs -l app=myapi --tail=50
```

### Check Status

```bash
# Quick status check
make status

# Detailed pod information
kubectl get pods -l app=myapi -o wide

# Describe deployment
kubectl describe deployment myapi-deployment
```

### Port Forwarding

```bash
# Forward local port 8080 to pod
make k8s-port-forward
# Then access: http://localhost:8080
```

## 🔧 Configuration

### Environment Variables

Configuration is managed through the ConfigMap in `k8s/configmap.yaml`:

```yaml
ASPNETCORE_ENVIRONMENT: "Production"
ASPNETCORE_URLS: "http://+:8080"
LOGGING__LOGLEVEL__DEFAULT: "Information"
```

### Resource Limits

Each pod is configured with:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Auto-Scaling Configuration

HPA is configured in `k8s/hpa.yaml`:

```yaml
minReplicas: 2
maxReplicas: 10
metrics:
- CPU: 70% utilization
- Memory: 80% utilization
```

### Security

- ✅ Non-root user (UID 1001)
- ✅ Read-only root filesystem
- ✅ No privilege escalation
- ✅ Dropped all capabilities
- ✅ Security context enforcement

## 🐛 Troubleshooting

### Common Issues

#### 1. Registry Connection Issues

```bash
# Check if registry is running
curl http://localhost:5000/v2/

# Restart registry
make registry-stop
make registry-start
```

#### 2. Docker Insecure Registry

Add to Docker daemon configuration (`~/.docker/daemon.json`):

```json
{
  "insecure-registries": ["localhost:5000"]
}
```

#### 3. Kubernetes Connection

```bash
# Check cluster connection
kubectl cluster-info

# Check node availability
kubectl get nodes
```

#### 4. Image Pull Issues

```bash
# Check if image exists in registry
curl http://localhost:5000/v2/_catalog

# Rebuild and push
make build
```

#### 5. Pod Issues

```bash
# Check pod status
kubectl get pods -l app=myapi

# Describe problematic pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

#### 6. HPA Not Working (Metrics Server Issues)

**Error**: `unable to get metrics for resource cpu: unable to fetch metrics from resource metrics API`

**Solution**:
```bash
# Quick fix - run the metrics server fix script
make fix-metrics

# Or manually check metrics server
kubectl get pods -n kube-system | grep metrics-server

# Test if metrics are working
kubectl top nodes
kubectl top pods

# Check HPA status after fix
kubectl describe hpa myapi-hpa
```

The setup now automatically installs a properly configured metrics server for local development clusters.

### Logs and Debugging

```bash
# Application logs
make logs

# Kubernetes events
kubectl get events

# Pod description
kubectl describe deployment myapi-deployment

# Service endpoints
kubectl get endpoints myapi-service
```

## 🧹 Cleanup

```bash
# Complete cleanup
make clean

# Manual cleanup
kubectl delete -f k8s/
docker-compose down
docker rmi localhost:5000/myapi:latest
```

## 🏗️ Development Notes

### Local Development

For local development without Kubernetes:

```bash
# Run locally with .NET
cd src
dotnet run

# Or with Docker
make docker-run
```

### Customization

- **Port changes**: Update `ASPNETCORE_URLS` in configmap and service definitions
- **Replica count**: Modify `replicas` in `k8s/deployment.yaml`
- **Resource limits**: Adjust in `k8s/deployment.yaml`
- **Image tag**: Pass tag to build script: `./scripts/build.sh v1.0.0`

### CI/CD Integration

This setup can be extended for CI/CD:

1. Replace local registry with cloud registry (ECR, ACR, GCR)
2. Add image versioning/tagging strategy
3. Implement rolling deployment strategies
4. Add automated testing pipeline

## 📚 Additional Resources

- [.NET 8 Documentation](https://docs.microsoft.com/en-us/dotnet/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `make dev`
5. Submit a pull request

---

**Happy coding! 🚀**