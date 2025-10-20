# Docker Deployment Guide

This guide covers how to build, run, and deploy Open Deep Research using Docker.

## Prerequisites

- Docker installed on your system
- Docker Compose (usually comes with Docker Desktop)
- `.env` file configured with your API keys

## Quick Start

### 1. Environment Setup

First, create your environment file:

```bash
cp env.example .env
# Edit .env with your API keys
```

Required API keys:
- `GOOGLE_API_KEY` - Google AI (Gemini) API key
- `TAVILY_API_KEY` - Tavily search API key
- `LANGSMITH_API_KEY` - LangSmith API key for tracing

### 2. Build and Run with Docker Compose

```bash
# Build and start the container
docker-compose up --build

# Or run in detached mode
docker-compose up -d --build
```

### 3. Access the Application

Once running, you can access:

- **API**: http://localhost:2024
- **API Documentation**: http://localhost:2024/docs
- **LangGraph Studio**: https://smith.langchain.com/studio/?baseUrl=http://localhost:2024

### 4. Stop the Application

```bash
# Stop and remove containers
docker-compose down

# Stop and remove containers with volumes
docker-compose down -v
```

## Manual Docker Commands

### Build the Image

```bash
# Build the Docker image
docker build -t open-deep-research .

# Build with specific tag
docker build -t open-deep-research:latest .
```

### Run the Container

```bash
# Run with environment file
docker run -d \
  --name open-deep-research \
  --env-file .env \
  -p 2024:2024 \
  -v $(pwd)/output:/app/output \
  open-deep-research

# Run with specific environment variables
docker run -d \
  --name open-deep-research \
  -e GOOGLE_API_KEY="your_key" \
  -e TAVILY_API_KEY="your_key" \
  -e LANGSMITH_API_KEY="your_key" \
  -p 2024:2024 \
  open-deep-research
```

### Container Management

```bash
# View running containers
docker ps

# View logs
docker logs open-deep-research

# Follow logs
docker logs -f open-deep-research

# Stop container
docker stop open-deep-research

# Remove container
docker rm open-deep-research

# Remove image
docker rmi open-deep-research
```

## Configuration

### Environment Variables

The application can be configured using environment variables. See `env.example` for all available options.

Key configuration areas:
- **Model Selection**: Choose different LLM providers
- **Search Configuration**: Configure search depth and results
- **Report Settings**: Customize output format and metadata
- **Logging**: Set log levels and debug mode

### Volume Mounts

The container uses the following volume mounts:
- `/app/output` - Research output files (mounted from `./output`)

### Resource Limits

Docker Compose includes resource limits:
- Memory: 4GB limit, 2GB request
- CPU: 2 cores limit, 1 core request

## Health Checks

The container includes health checks that verify the application is responding:

```bash
# Check container health
docker inspect open-deep-research | grep Health -A 10

# Manual health check
curl -f http://localhost:2024/health
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using port 2024
   lsof -i :2024
   
   # Kill the process or use different port
   docker run -p 2025:2024 open-deep-research
   ```

2. **Permission Denied on Output Directory**
   ```bash
   # Create output directory with proper permissions
   mkdir -p output
   chmod 755 output
   ```

3. **Container Won't Start**
   ```bash
   # Check logs for errors
   docker logs open-deep-research
   
   # Check if environment variables are set
   docker exec open-deep-research env | grep API_KEY
   ```

4. **API Keys Not Working**
   - Verify API keys are correctly set in `.env`
   - Check if API keys have proper permissions
   - Ensure no extra spaces or quotes in `.env` file

### Debug Mode

Enable debug mode for more verbose logging:

```bash
# In .env file
DEBUG=true
LOG_LEVEL=DEBUG

# Or via environment variable
docker run -e DEBUG=true -e LOG_LEVEL=DEBUG open-deep-research
```

### Container Shell Access

```bash
# Access container shell
docker exec -it open-deep-research /bin/bash

# Check Python environment
docker exec -it open-deep-research python --version
docker exec -it open-deep-research pip list
```

## Production Considerations

### Security

- Never commit `.env` files to version control
- Use Docker secrets for sensitive data in production
- Run container as non-root user (already configured)
- Regularly update base images for security patches

### Performance

- Monitor resource usage: `docker stats open-deep-research`
- Adjust resource limits based on workload
- Consider using multi-stage builds for smaller images
- Use `.dockerignore` to exclude unnecessary files

### Monitoring

- Set up log aggregation for container logs
- Monitor health check endpoints
- Use Docker health checks for automatic restart
- Consider using Docker Swarm or Kubernetes for orchestration

## Next Steps

- For production deployment, see [GKE Deployment Guide](GKE_DEPLOYMENT.md)
- For local development, see the main [README.md](../README.md)
- For configuration options, see [configuration.py](../src/open_deep_research/configuration.py)
