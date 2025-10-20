#!/bin/bash

# Interactive script to create Kubernetes secrets for Open Deep Research
# Usage: ./scripts/create-k8s-secrets.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}[SECRETS]${NC} $1"
}

# Function to read input securely
read_secret() {
    local prompt="$1"
    local var_name="$2"
    local is_required="$3"
    
    while true; do
        if [ "$is_required" = "true" ]; then
            read -s -p "$prompt: " value
            echo
            if [ -n "$value" ]; then
                eval "$var_name='$value'"
                break
            else
                print_error "This field is required. Please enter a value."
            fi
        else
            read -p "$prompt (optional): " value
            eval "$var_name='$value'"
            break
        fi
    done
}

print_header "Creating Kubernetes Secrets for Open Deep Research"
print_warning "This script will create a Kubernetes secret with your API keys"
print_warning "Make sure you're connected to the correct cluster"

echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    print_error "Not connected to a Kubernetes cluster"
    print_status "Please connect to your cluster first:"
    echo "  gcloud container clusters get-credentials <cluster-name> --zone=<zone>"
    exit 1
fi

print_status "Connected to cluster: $(kubectl config current-context)"

echo ""
print_status "Enter your API keys (press Enter to skip optional ones):"
echo ""

# Required API keys
read_secret "Google API Key (required)" GOOGLE_API_KEY "true"
read_secret "Tavily API Key (required)" TAVILY_API_KEY "true"
read_secret "LangSmith API Key (required)" LANGSMITH_API_KEY "true"

echo ""

# Optional API keys
read_secret "OpenAI API Key" OPENAI_API_KEY "false"
read_secret "Anthropic API Key" ANTHROPIC_API_KEY "false"
read_secret "Groq API Key" GROQ_API_KEY "false"
read_secret "DeepSeek API Key" DEEPSEEK_API_KEY "false"
read_secret "Exa API Key" EXA_API_KEY "false"

echo ""

# Create temporary secret file
SECRET_FILE=$(mktemp)
cat > "$SECRET_FILE" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: open-deep-research-secrets
  labels:
    app: open-deep-research
    component: research-agent
type: Opaque
data:
  google_api_key: $(echo -n "$GOOGLE_API_KEY" | base64)
  tavily_api_key: $(echo -n "$TAVILY_API_KEY" | base64)
  langsmith_api_key: $(echo -n "$LANGSMITH_API_KEY" | base64)
EOF

# Add optional keys if provided
if [ -n "$OPENAI_API_KEY" ]; then
    echo "  openai_api_key: $(echo -n "$OPENAI_API_KEY" | base64)" >> "$SECRET_FILE"
fi

if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "  anthropic_api_key: $(echo -n "$ANTHROPIC_API_KEY" | base64)" >> "$SECRET_FILE"
fi

if [ -n "$GROQ_API_KEY" ]; then
    echo "  groq_api_key: $(echo -n "$GROQ_API_KEY" | base64)" >> "$SECRET_FILE"
fi

if [ -n "$DEEPSEEK_API_KEY" ]; then
    echo "  deepseek_api_key: $(echo -n "$DEEPSEEK_API_KEY" | base64)" >> "$SECRET_FILE"
fi

if [ -n "$EXA_API_KEY" ]; then
    echo "  exa_api_key: $(echo -n "$EXA_API_KEY" | base64)" >> "$SECRET_FILE"
fi

# Apply the secret
print_status "Creating secret in Kubernetes..."
kubectl apply -f "$SECRET_FILE"

# Verify the secret was created
print_status "Verifying secret creation..."
kubectl get secret open-deep-research-secrets

# Clean up temporary file
rm "$SECRET_FILE"

print_header "Secret created successfully!"
print_status "You can now deploy the application using:"
echo "  ./scripts/deploy-to-gke.sh <PROJECT_ID>"
echo ""
print_status "To view the secret:"
echo "  kubectl get secret open-deep-research-secrets -o yaml"
echo ""
print_warning "Remember: Never commit secret files to version control!"
