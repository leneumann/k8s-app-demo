#!/bin/bash

echo "🔍 Monitoring HPA and Pod Scaling"
echo "=================================="
echo "Press Ctrl+C to exit"
echo ""

# Function to show status
show_status() {
    clear
    echo "🔍 Auto-Scaling Monitor - $(date)"
    echo "=================================="
    echo ""
    
    echo "📊 HPA Status:"
    kubectl get hpa myapi-hpa -n k8s-app-demo 2>/dev/null || echo "❌ HPA not found"
    echo ""
    
    echo "🔋 Pod Status:"
    kubectl get pods -l app=myapi -n k8s-app-demo -o wide 2>/dev/null || echo "❌ No pods found"
    echo ""
    
    echo "📈 Pod Count:"
    POD_COUNT=$(kubectl get pods -l app=myapi -n k8s-app-demo --no-headers 2>/dev/null | wc -l)
    echo "   Current: ${POD_COUNT} pods"
    echo ""
    
    echo "📋 Recent HPA Events:"
    kubectl get events --sort-by='.lastTimestamp' 2>/dev/null | grep -i "horizontalpodautoscaler\|scaled" | tail -3 || echo "   No recent events"
    echo ""
    
    echo "💡 To generate load: make load-test (in another terminal)"
    echo "⏹️  Press Ctrl+C to exit"
}

# Main monitoring loop
while true; do
    show_status
    sleep 5
done