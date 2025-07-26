#!/bin/bash

set -e

# Configuration
IMAGE_NAME="myapi"
REGISTRY="localhost:5000"
TAG=${1:-latest}
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "🔨 Building Docker image: ${FULL_IMAGE_NAME}"

# Build the Docker image
docker build -t "${FULL_IMAGE_NAME}" .

# Push to local registry
echo "📤 Pushing image to local registry..."
docker push "${FULL_IMAGE_NAME}"

echo "✅ Image built and pushed successfully: ${FULL_IMAGE_NAME}"

# Show registry contents
echo "📋 Registry catalog:"
curl -s http://localhost:5000/v2/_catalog | jq '.' || echo "Registry catalog not available"