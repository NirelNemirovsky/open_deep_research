#!/bin/bash

# Deploy Open Deep Research to Google Kubernetes Engine
# Usage: ./scripts/deploy-to-gke.sh [PROJECT_ID] [CLUSTER_NAME] [ZONE]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_ID=${1:-""}
CLUSTER_NAME=${2:-"open-deep-research-cluster"}
ZONE=${3:-"us-central1-a"}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Check if PROJECT_ID is provided
if [ -z "$PROJECT_ID" ]; then
    print_error "PROJECT_ID is required"
    echo "Usage: $0 <PROJECT_ID> [CLUSTER_NAME] [ZONE]"
    echo "Example: $0 my-gcp-project open-deep-research-cluster us-central1-a"
    exit 1
fi

print_header "Deploying Open Deep Research to GKE"
print_status "Project ID: $PROJECT_ID"
print_status "Cluster: $CLUSTER_NAME"
print_status "Zone: $ZONE"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first."
    echo "Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
    echo "Visit: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Set the project
print_status "Setting GCP project..."
gcloud config set project "$PROJECT_ID"

# Check if cluster exists
print_status "Checking if cluster exists..."
if ! gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" &> /dev/null; then
    print_warning "Cluster '$CLUSTER_NAME' not found in zone '$ZONE'"
    print_status "Creating GKE cluster..."
    
    gcloud container clusters create "$CLUSTER_NAME" \
        --zone="$ZONE" \
        --machine-type=e2-standard-4 \
        --num-nodes=2 \
        --enable-autoscaling \
        --min-nodes=1 \
        --max-nodes=5 \
        --enable-autorepair \
        --enable-autoupgrade \
        --disk-size=50GB \
        --disk-type=pd-standard
else
    print_status "Cluster found, getting credentials..."
    gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE"
fi

# Verify cluster connection
print_status "Verifying cluster connection..."
kubectl cluster-info

# Check if secrets exist
print_status "Checking for required secrets..."
if ! kubectl get secret open-deep-research-secrets &> /dev/null; then
    print_error "Secret 'open-deep-research-secrets' not found!"
    print_warning "Please create the secret first using:"
    echo "  ./scripts/create-k8s-secrets.sh"
    echo "  OR"
    echo "  kubectl apply -f k8s/secret.yaml"
    exit 1
fi

# Apply Kubernetes manifests in order
print_status "Applying Kubernetes manifests..."

print_status "Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml

print_status "Applying Service..."
kubectl apply -f k8s/service.yaml

print_status "Applying Deployment..."
kubectl apply -f k8s/deployment.yaml

# Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl rollout status deployment/open-deep-research --timeout=300s

# Verify deployment
print_status "Verifying deployment..."
kubectl get pods -l app=open-deep-research
kubectl get services -l app=open-deep-research

# Display access information
print_header "Deployment completed successfully!"
print_status "Service is running internally (ClusterIP)"
print_status "To access the service, use port-forwarding:"
echo ""
echo "  kubectl port-forward service/open-deep-research 2024:2024"
echo ""
print_status "Then access the API at: http://localhost:2024"
print_status "API Documentation: http://localhost:2024/docs"
print_status "LangGraph Studio: https://smith.langchain.com/studio/?baseUrl=http://localhost:2024"
echo ""
print_status "To check logs:"
echo "  kubectl logs -l app=open-deep-research -f"
echo ""
print_status "To scale the deployment:"
echo "  kubectl scale deployment open-deep-research --replicas=3"
