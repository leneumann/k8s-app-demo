#!/bin/bash

set -e

echo "🔧 Fixing Metrics Server for HPA..."

# Check if metrics server is already running
echo "📊 Checking current metrics server status..."
if kubectl get pods -n kube-system | grep -q "metrics-server.*Running"; then
    echo "✅ Metrics server is already running"
    
    # Test if it's working
    if kubectl top nodes >/dev/null 2>&1; then
        echo "✅ Metrics server is working correctly"
        echo "📋 Current node metrics:"
        kubectl top nodes
        exit 0
    else
        echo "⚠️  Metrics server is running but not working properly"
        echo "🔄 Will reinstall with proper configuration..."
    fi
else
    echo "❌ Metrics server not found or not running"
fi

# Detect cluster type
CLUSTER_TYPE="unknown"
if kubectl config current-context | grep -q "docker-desktop"; then
    CLUSTER_TYPE="docker-desktop"
elif kubectl config current-context | grep -q "minikube"; then
    CLUSTER_TYPE="minikube"
elif kubectl config current-context | grep -q "kind"; then
    CLUSTER_TYPE="kind"
fi

echo "🎯 Detected cluster type: $CLUSTER_TYPE"

# Install or reinstall metrics server
echo "📦 Installing metrics server..."

# Delete existing metrics server if present
kubectl delete deployment metrics-server -n kube-system 2>/dev/null || true
kubectl delete service metrics-server -n kube-system 2>/dev/null || true
kubectl delete apiservice v1beta1.metrics.k8s.io 2>/dev/null || true

# Wait a moment for cleanup
sleep 5

# Apply metrics server with appropriate configuration for local development
echo "🚀 Applying metrics server configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-view: "true"
  name: system:aggregated-metrics-reader
rules:
- apiGroups:
  - metrics.k8s.io
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - nodes/metrics
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    k8s-app: metrics-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        - --requestheader-client-ca-file=/tmp/server-ca.crt
        - --requestheader-username-headers=X-Remote-User
        - --requestheader-group-headers=X-Remote-Group
        - --requestheader-extra-headers-prefix=X-Remote-Extra-
        image: registry.k8s.io/metrics-server/metrics-server:v0.7.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 4443
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
        - mountPath: /tmp/server-ca.crt
          name: ca-certs
          readOnly: true
          subPath: requestheader-client-ca-file
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
      - configMap:
          name: extension-apiserver-authentication
          optional: true
        name: ca-certs
---
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  labels:
    k8s-app: metrics-server
  name: v1beta1.metrics.k8s.io
spec:
  group: metrics.k8s.io
  groupPriorityMinimum: 100
  insecureSkipTLSVerify: true
  service:
    name: metrics-server
    namespace: kube-system
  version: v1beta1
  versionPriority: 100
EOF

echo "⏳ Waiting for metrics server to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system

echo "🔍 Testing metrics server..."
sleep 10

# Test metrics server
if kubectl top nodes >/dev/null 2>&1; then
    echo "✅ Metrics server is working correctly!"
    echo ""
    echo "📊 Node metrics:"
    kubectl top nodes
    echo ""
    echo "📊 Pod metrics (if any pods exist):"
    kubectl top pods --all-namespaces | head -10
    echo ""
    echo "🎯 Testing HPA..."
    kubectl get hpa myapi-hpa 2>/dev/null || echo "HPA not deployed yet - run 'make deploy' first"
else
    echo "❌ Metrics server still not working properly"
    echo "📋 Troubleshooting information:"
    echo ""
    echo "Metrics server pod status:"
    kubectl get pods -n kube-system -l k8s-app=metrics-server
    echo ""
    echo "Metrics server logs:"
    kubectl logs -n kube-system -l k8s-app=metrics-server --tail=20
    exit 1
fi

echo ""
echo "✅ Metrics server setup completed!"
echo "💡 You can now use HPA and the load testing commands"