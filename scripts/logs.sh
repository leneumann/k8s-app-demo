#!/bin/bash

# Configuration
POD_SELECTOR="app=myapi"

echo "📋 MyApi Pod Logs"
echo "=================="

# Show current pods
echo "Current pods:"
kubectl get pods -l ${POD_SELECTOR}
echo ""

# Get logs from all pods
PODS=$(kubectl get pods -l ${POD_SELECTOR} -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
    echo "❌ No pods found with selector: ${POD_SELECTOR}"
    exit 1
fi

for POD in $PODS; do
    echo "📋 Logs for pod: $POD"
    echo "----------------------------------------"
    kubectl logs $POD --tail=50
    echo ""
done

# Follow logs from the first pod if requested
if [ "$1" = "-f" ] || [ "$1" = "--follow" ]; then
    FIRST_POD=$(echo $PODS | cut -d' ' -f1)
    echo "👀 Following logs for pod: $FIRST_POD"
    kubectl logs -f $FIRST_POD
fi