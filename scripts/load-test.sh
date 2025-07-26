#!/bin/bash

set -e

# Configuration
API_URL="http://localhost:30081"
DURATION=${1:-120}  # Default 2 minutes
CONCURRENT=${2:-10} # Default 10 concurrent requests

echo "🔥 Starting load test..."
echo "   URL: ${API_URL}"
echo "   Duration: ${DURATION} seconds"
echo "   Concurrent requests: ${CONCURRENT}"
echo ""
echo "💡 In another terminal, watch scaling with: watch kubectl get hpa myapi-hpa"
echo ""

# Check if API is accessible
if ! curl -s -f "${API_URL}/health" > /dev/null 2>&1; then
    echo "❌ API not accessible at ${API_URL}"
    echo "   Make sure the application is deployed: make deploy"
    exit 1
fi

# Function to generate load
generate_load() {
    local worker_id=$1
    local end_time=$(($(date +%s) + DURATION))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Multiple API calls to increase CPU/memory usage
        curl -s "${API_URL}/api/users" > /dev/null 2>&1 &
        curl -s "${API_URL}/health" > /dev/null 2>&1 &
        curl -s "${API_URL}/" > /dev/null 2>&1 &
        
        # Create some users to increase memory usage
        curl -s -X POST "${API_URL}/api/users" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"LoadTest${worker_id}\",\"email\":\"test${worker_id}@example.com\"}" \
            > /dev/null 2>&1 &
        
        sleep 0.1  # Small delay between requests
    done
}

# Start concurrent load generators
echo "🚀 Starting ${CONCURRENT} load generators..."
for i in $(seq 1 $CONCURRENT); do
    generate_load $i &
    echo "   Worker $i started (PID: $!)"
done

# Show initial HPA status
echo ""
echo "📊 Initial HPA status:"
kubectl get hpa myapi-hpa 2>/dev/null || echo "HPA not found - make sure metrics server is running"

echo ""
echo "⏳ Load test running for ${DURATION} seconds..."
echo "   Monitor with: watch 'kubectl get hpa myapi-hpa && kubectl get pods -l app=myapi'"

# Progress indicator
for i in $(seq 1 $DURATION); do
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "."
        if [ $((i % 60)) -eq 0 ]; then
            echo " ${i}s"
            # Show current status every minute
            kubectl get hpa myapi-hpa 2>/dev/null | tail -1 || true
        fi
    fi
    sleep 1
done

echo ""
echo "🛑 Stopping load generators..."

# Kill all background jobs
jobs -p | xargs -r kill 2>/dev/null || true
wait 2>/dev/null || true

echo ""
echo "✅ Load test completed!"
echo ""
echo "📊 Final status:"
kubectl get hpa myapi-hpa 2>/dev/null || echo "HPA not available"
kubectl get pods -l app=myapi --no-headers | wc -l | xargs echo "Current pod count:"

echo ""
echo "💡 Tips:"
echo "   - HPA takes 1-2 minutes to react to load changes"
echo "   - Scale down takes 5+ minutes due to stabilization window"
echo "   - Check events: kubectl get events --sort-by='.lastTimestamp' | grep HPA"