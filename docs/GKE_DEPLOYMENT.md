# GKE Deployment Guide

This guide covers deploying Open Deep Research to Google Kubernetes Engine (GKE) for production use.

## Prerequisites

- Google Cloud Platform account with billing enabled
- `gcloud` CLI installed and authenticated
- `kubectl` installed
- Docker installed (for building images)
- GCP project with Container Registry or Artifact Registry enabled

## Quick Start

### 1. Set Up Your GCP Project

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 2. Create Kubernetes Secrets

```bash
# Interactive script to create secrets
./scripts/create-k8s-secrets.sh

# Or manually create from template
cp k8s/secret.yaml.template k8s/secret.yaml
# Edit k8s/secret.yaml with your API keys (base64 encoded)
kubectl apply -f k8s/secret.yaml
```

### 3. Build and Push Docker Image

```bash
# Build and push to Google Container Registry
./scripts/build-and-push.sh $PROJECT_ID latest
```

### 4. Deploy to GKE

```bash
# Deploy to GKE (creates cluster if needed)
./scripts/deploy-to-gke.sh $PROJECT_ID open-deep-research-cluster us-central1-a
```

### 5. Access the Application

```bash
# Port forward to access the service
kubectl port-forward service/open-deep-research 2024:2024

# Access the API
curl http://localhost:2024/health
```

## Detailed Setup

### GCP Project Configuration

1. **Create or Select Project**
   ```bash
   # List existing projects
   gcloud projects list
   
   # Create new project (optional)
   gcloud projects create $PROJECT_ID --name="Open Deep Research"
   ```

2. **Enable Required APIs**
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   ```

3. **Set Up Authentication**
   ```bash
   # Login to Google Cloud
   gcloud auth login
   
   # Set default project
   gcloud config set project $PROJECT_ID
   
   # Configure Docker authentication
   gcloud auth configure-docker
   ```

### GKE Cluster Setup

#### Option 1: Use Deployment Script (Recommended)

The deployment script will automatically create a cluster if it doesn't exist:

```bash
./scripts/deploy-to-gke.sh $PROJECT_ID
```

#### Option 2: Manual Cluster Creation

```bash
# Create GKE cluster
gcloud container clusters create open-deep-research-cluster \
    --zone=us-central1-a \
    --machine-type=e2-standard-4 \
    --num-nodes=2 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5 \
    --enable-autorepair \
    --enable-autoupgrade \
    --disk-size=50GB \
    --disk-type=pd-standard

# Get cluster credentials
gcloud container clusters get-credentials open-deep-research-cluster --zone=us-central1-a
```

### Secret Management

#### Using the Interactive Script

```bash
# Run the interactive secret creation script
./scripts/create-k8s-secrets.sh
```

This script will:
- Prompt for required API keys
- Base64 encode the values
- Create the Kubernetes secret
- Verify the secret was created

#### Manual Secret Creation

1. **Create Secret from Template**
   ```bash
   cp k8s/secret.yaml.template k8s/secret.yaml
   ```

2. **Edit the Secret File**
   Replace placeholder values with base64-encoded API keys:
   ```bash
   # Encode your API key
   echo -n "your_google_api_key" | base64
   
   # Update secret.yaml with the encoded value
   ```

3. **Apply the Secret**
   ```bash
   kubectl apply -f k8s/secret.yaml
   ```

#### Using Google Secret Manager (Advanced)

For production environments, consider using Google Secret Manager:

```bash
# Store secrets in Secret Manager
gcloud secrets create google-api-key --data-file=- <<< "your_google_api_key"
gcloud secrets create tavily-api-key --data-file=- <<< "your_tavily_api_key"

# Create secret from Secret Manager
kubectl create secret generic open-deep-research-secrets \
    --from-literal=google_api_key="$(gcloud secrets versions access latest --secret=google-api-key)" \
    --from-literal=tavily_api_key="$(gcloud secrets versions access latest --secret=tavily-api-key)"
```

### Image Building and Pushing

#### Using the Build Script

```bash
# Build and push with latest tag
./scripts/build-and-push.sh $PROJECT_ID latest

# Build and push with specific tag
./scripts/build-and-push.sh $PROJECT_ID v1.0.0
```

#### Manual Build Process

```bash
# Build the image
docker build -t gcr.io/$PROJECT_ID/open-deep-research:latest .

# Push to Google Container Registry
docker push gcr.io/$PROJECT_ID/open-deep-research:latest
```

### Deployment

#### Using the Deployment Script

```bash
# Deploy with default settings
./scripts/deploy-to-gke.sh $PROJECT_ID

# Deploy with custom cluster name and zone
./scripts/deploy-to-gke.sh $PROJECT_ID my-cluster us-west1-a
```

#### Manual Deployment

```bash
# Apply Kubernetes manifests in order
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/deployment.yaml

# Wait for deployment to be ready
kubectl rollout status deployment/open-deep-research
```

## Accessing the Application

### Internal Access (ClusterIP)

The service is configured as ClusterIP (internal only). To access it:

```bash
# Port forward to local machine
kubectl port-forward service/open-deep-research 2024:2024

# Access the API
curl http://localhost:2024/health
```

### Using Cloud Shell

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=open-deep-research -o jsonpath='{.items[0].metadata.name}')

# Port forward in Cloud Shell
kubectl port-forward $POD_NAME 2024:2024
```

### Creating a Load Balancer (Optional)

If you need external access, create a LoadBalancer service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: open-deep-research-lb
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 2024
  selector:
    app: open-deep-research
```

## Monitoring and Management

### Viewing Logs

```bash
# View logs from all pods
kubectl logs -l app=open-deep-research -f

# View logs from specific pod
kubectl logs <pod-name> -f

# View logs with timestamps
kubectl logs -l app=open-deep-research --timestamps
```

### Scaling the Application

```bash
# Scale to 3 replicas
kubectl scale deployment open-deep-research --replicas=3

# Enable horizontal pod autoscaling
kubectl autoscale deployment open-deep-research --cpu-percent=70 --min=2 --max=10
```

### Updating the Application

```bash
# Update image
kubectl set image deployment/open-deep-research open-deep-research=gcr.io/$PROJECT_ID/open-deep-research:v1.1.0

# Check rollout status
kubectl rollout status deployment/open-deep-research

# Rollback if needed
kubectl rollout undo deployment/open-deep-research
```

### Health Checks

```bash
# Check pod health
kubectl get pods -l app=open-deep-research

# Check service endpoints
kubectl get endpoints open-deep-research

# Check deployment status
kubectl get deployment open-deep-research
```

## Configuration Management

### Updating Configuration

```bash
# Edit ConfigMap
kubectl edit configmap open-deep-research-config

# Restart deployment to pick up changes
kubectl rollout restart deployment/open-deep-research
```

### Environment-Specific Configurations

Create different ConfigMaps for different environments:

```bash
# Development
kubectl create configmap open-deep-research-config-dev --from-file=config-dev.yaml

# Production
kubectl create configmap open-deep-research-config-prod --from-file=config-prod.yaml
```

## Troubleshooting

### Common Issues

1. **Pods Not Starting**
   ```bash
   # Check pod status
   kubectl describe pod <pod-name>
   
   # Check events
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

2. **Image Pull Errors**
   ```bash
   # Check if image exists
   gcloud container images list --repository=gcr.io/$PROJECT_ID
   
   # Check image tags
   gcloud container images list-tags gcr.io/$PROJECT_ID/open-deep-research
   ```

3. **Secret Issues**
   ```bash
   # Check if secret exists
   kubectl get secret open-deep-research-secrets
   
   # Decode secret values
   kubectl get secret open-deep-research-secrets -o jsonpath='{.data.google_api_key}' | base64 -d
   ```

4. **Service Not Accessible**
   ```bash
   # Check service endpoints
   kubectl get endpoints open-deep-research
   
   # Test from within cluster
   kubectl run test-pod --image=busybox --rm -it -- wget -qO- http://open-deep-research:2024/health
   ```

### Debug Commands

```bash
# Get detailed pod information
kubectl describe pod <pod-name>

# Execute shell in pod
kubectl exec -it <pod-name> -- /bin/bash

# Check resource usage
kubectl top pods -l app=open-deep-research

# Check node resources
kubectl top nodes
```

## Cost Optimization

### Resource Management

```bash
# Set appropriate resource requests and limits
kubectl patch deployment open-deep-research -p '{"spec":{"template":{"spec":{"containers":[{"name":"open-deep-research","resources":{"requests":{"memory":"1Gi","cpu":"500m"},"limits":{"memory":"2Gi","cpu":"1000m"}}}]}}}}'
```

### Cluster Optimization

- Use preemptible nodes for non-critical workloads
- Enable cluster autoscaling
- Use appropriate machine types
- Monitor resource usage and adjust accordingly

### Cleanup

```bash
# Delete deployment
kubectl delete deployment open-deep-research

# Delete service
kubectl delete service open-deep-research

# Delete secrets
kubectl delete secret open-deep-research-secrets

# Delete cluster (if no longer needed)
gcloud container clusters delete open-deep-research-cluster --zone=us-central1-a
```

## Security Best Practices

1. **Use Workload Identity** for service account authentication
2. **Enable Pod Security Standards** for better isolation
3. **Use Network Policies** to restrict pod communication
4. **Regularly update** base images and dependencies
5. **Monitor** for security vulnerabilities
6. **Use least privilege** for service accounts

## Next Steps

- Set up monitoring with Google Cloud Monitoring
- Configure log aggregation with Google Cloud Logging
- Implement CI/CD pipeline for automated deployments
- Set up backup and disaster recovery procedures
- Consider using Google Cloud Run for serverless deployment
