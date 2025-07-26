#!/bin/bash

echo "Starting local Docker registry..."
docker-compose up -d registry

echo "Waiting for registry to be ready..."
sleep 5

# Test registry connectivity
if curl -f http://localhost:5000/v2/ > /dev/null 2>&1; then
    echo "✅ Local registry is running at http://localhost:5000"
    echo "Registry catalog: http://localhost:5000/v2/_catalog"
else
    echo "❌ Failed to start local registry"
    exit 1
fi