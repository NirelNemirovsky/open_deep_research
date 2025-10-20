# 🐳 Docker Deployment Guide

This guide explains how to deploy Open Deep Research using Docker and Docker Compose.

## 📋 Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- Git

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/langchain-ai/open_deep_research.git
cd open_deep_research
```

### 2. Environment Configuration

Copy the environment template and configure your API keys:

```bash
cp env.example .env
```

Edit the `.env` file with your API keys:

```bash
# Required API keys
GOOGLE_API_KEY=your_google_api_key_here
TAVILY_API_KEY=your_tavily_api_key_here

# Optional: Other providers
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

### 3. Build and Run

#### Option A: Using Makefile (Recommended)

```bash
# Quick setup for new users
make setup

# Start the services
make up

# Or build and start in one command
make up-build
```

#### Option B: Using Docker Compose directly

```bash
# Build and start the service
docker-compose up --build

# Run in detached mode
docker-compose up -d --build
```

#### Option B: Using Docker directly

```bash
# Build the image
docker build -t open-deep-research .

# Run the container
docker run -p 2024:2024 --env-file .env open-deep-research
```

### 4. Access the Application

Once running, you can access:

- **🚀 API**: http://localhost:2024
- **🎨 LangGraph Studio**: https://smith.langchain.com/studio/?baseUrl=http://localhost:2024
- **📚 API Docs**: http://localhost:2024/docs

## 🛠️ Management Commands

### Using Makefile (Recommended)

The repository includes a `Makefile` with convenient commands for Docker management:

```bash
# Show all available commands
make help

# Quick setup for new users
make setup

# Start services
make up

# Build and start services
make up-build

# Stop services
make down

# Restart services
make restart

# View logs
make logs

# Run tests
make test

# Show service status
make status

# Clean up everything
make clean

# Production deployment with Nginx
make prod

# Stop production services
make prod-down
```

### Using Docker Compose directly

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and start
docker-compose up --build -d
```

## 🔧 Configuration Options

### Environment Variables

The application supports extensive configuration through environment variables:

#### Required Variables
- `GOOGLE_API_KEY`: Your Google AI (Gemini) API key
- `TAVILY_API_KEY`: Your Tavily search API key

#### Optional Variables
- `OPENAI_API_KEY`: For OpenAI models
- `ANTHROPIC_API_KEY`: For Claude models
- `GROQ_API_KEY`: For Groq models
- `LANGSMITH_API_KEY`: For LangSmith tracing
- `LANGSMITH_PROJECT`: LangSmith project name

#### Model Configuration
- `SUMMARIZATION_MODEL`: Model for summarization (default: `google:gemini-2.5-flash`)
- `RESEARCH_MODEL`: Model for research (default: `google:gemini-2.5-flash`)
- `COMPRESSION_MODEL`: Model for compression (default: `google:gemini-2.5-flash`)
- `FINAL_REPORT_MODEL`: Model for final report (default: `google:gemini-2.5-flash`)

### Docker Compose Profiles

#### Development Mode (Default)
```bash
docker-compose up
```

#### Production Mode (with Nginx)
```bash
docker-compose --profile production up
```

## 🏗️ Production Deployment

### Using Docker Compose with Nginx

For production deployments, use the production profile:

```bash
docker-compose --profile production up -d
```

This includes:
- Nginx reverse proxy
- Load balancing
- SSL termination (configure SSL certificates)
- Health checks
- Automatic restarts

### Environment-Specific Configurations

#### Development
```bash
# Use development settings
DEBUG=true
LOG_LEVEL=DEBUG
```

#### Production
```bash
# Use production settings
DEBUG=false
LOG_LEVEL=INFO
AUTH_ENABLED=true
```

#### Release Checklist

1. Copy and edit environment file
   ```bash
   cp env.example .env
   $EDITOR .env
   ```
2. Build and start services
   ```bash
   make up-build
   ```
3. Verify health and docs
   ```bash
   curl http://localhost:2024/health
   open http://localhost:2024/docs
   ```
4. Optional: run behind Nginx
   ```bash
   make prod
   ```
5. Optional: run smoke test
   ```bash
   make test
   ```

## 🔍 Monitoring and Health Checks

### Health Check Endpoint

The application includes a health check endpoint:

```bash
curl http://localhost:2024/health
```

### Docker Health Checks

The Dockerfile includes built-in health checks that monitor the application status.

### Logs

View application logs:

```bash
# Docker Compose
docker-compose logs -f

# Docker
docker logs -f <container_name>
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using port 2024
lsof -i :2024

# Kill the process or use a different port
docker-compose up -p 2025:2024
```

#### 2. API Key Issues
- Ensure all required API keys are set in `.env`
- Check that API keys are valid and have sufficient credits
- Verify environment variables are loaded correctly

#### 3. Build Failures
```bash
# Clean build (no cache)
docker-compose build --no-cache

# Remove old images
docker system prune -a
```

#### 4. Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
```

### Debug Mode

Enable debug mode for detailed logging:

```bash
# In .env file
DEBUG=true
LOG_LEVEL=DEBUG
```

## 📊 Performance Optimization

### Resource Limits

Add resource limits to docker-compose.yml:

```yaml
services:
  open-deep-research:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'
```

### Scaling

Scale the application:

```bash
# Scale to 3 instances
docker-compose up --scale open-deep-research=3
```

## 🔒 Security Considerations

### Production Security

1. **Use secrets management**:
   ```yaml
   services:
     open-deep-research:
       secrets:
         - openai_api_key
         - tavily_api_key
   ```

2. **Enable authentication**:
   ```bash
   AUTH_ENABLED=true
   AUTH_SECRET_KEY=your_secure_secret_key
   ```

3. **Use HTTPS in production**:
   - Configure SSL certificates in nginx.conf
   - Use Let's Encrypt for free SSL certificates

### Network Security

- Use Docker networks for service isolation
- Configure firewall rules
- Use reverse proxy for SSL termination

## 🚀 Deployment Examples

### Local Development
```bash
docker-compose up --build
```

### Staging Environment
```bash
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up
```

### Production Environment
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## 📝 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [Open Deep Research Repository](https://github.com/langchain-ai/open_deep_research)

## 🤝 Support

If you encounter issues with Docker deployment:

1. Check the logs: `docker-compose logs`
2. Verify environment variables: `docker-compose config`
3. Test the health endpoint: `curl http://localhost:2024/health`
4. Open an issue on the [GitHub repository](https://github.com/langchain-ai/open_deep_research/issues)
