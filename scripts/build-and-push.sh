#!/bin/bash

# Build and push Docker image to Google Container Registry
# Usage: ./scripts/build-and-push.sh [PROJECT_ID] [TAG]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PROJECT_ID=${1:-""}
TAG=${2:-"latest"}

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

# Check if PROJECT_ID is provided
if [ -z "$PROJECT_ID" ]; then
    print_error "PROJECT_ID is required"
    echo "Usage: $0 <PROJECT_ID> [TAG]"
    echo "Example: $0 my-gcp-project latest"
    exit 1
fi

# Get git commit SHA for tagging
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

print_status "Building Docker image for project: $PROJECT_ID"
print_status "Git SHA: $GIT_SHA"
print_status "Tag: $TAG"

# Configure Docker to use gcloud as a credential helper
print_status "Configuring Docker authentication..."
gcloud auth configure-docker --quiet

# Build the Docker image
IMAGE_NAME="gcr.io/$PROJECT_ID/open-deep-research"
print_status "Building image: $IMAGE_NAME:$TAG"

docker build -t "$IMAGE_NAME:$TAG" .

# Also tag with git SHA if available
if [ "$GIT_SHA" != "unknown" ]; then
    docker tag "$IMAGE_NAME:$TAG" "$IMAGE_NAME:$GIT_SHA"
    print_status "Also tagged as: $IMAGE_NAME:$GIT_SHA"
fi

# Push the image
print_status "Pushing image to Google Container Registry..."
docker push "$IMAGE_NAME:$TAG"

if [ "$GIT_SHA" != "unknown" ]; then
    docker push "$IMAGE_NAME:$GIT_SHA"
fi

print_status "Successfully pushed image: $IMAGE_NAME:$TAG"
if [ "$GIT_SHA" != "unknown" ]; then
    print_status "Also pushed: $IMAGE_NAME:$GIT_SHA"
fi

print_status "Build and push completed successfully!"
print_warning "Don't forget to update the image tag in k8s/deployment.yaml if using a specific tag"
