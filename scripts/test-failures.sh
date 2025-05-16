#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting failure simulation tests...${NC}"

# Function to check pod status
check_pod_status() {
    local namespace=$1
    local pod=$2
    kubectl get pod -n $namespace $pod -o jsonpath='{.status.phase}' 2>/dev/null
}

# Function to wait for pod to be ready
wait_for_pod() {
    local namespace=$1
    local pod=$2
    local timeout=60
    local interval=5
    local elapsed=0

    echo -e "\n${YELLOW}Waiting for $pod to be ready...${NC}"
    while [ $elapsed -lt $timeout ]; do
        status=$(check_pod_status $namespace $pod)
        if [ "$status" == "Running" ]; then
            echo -e "${GREEN}✓ $pod is running${NC}"
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -n "."
    done
    echo -e "\n${RED}✗ Timeout waiting for $pod${NC}"
    return 1
}

# Test 1: Delete a pod and verify recovery
echo -e "\n${YELLOW}Test 1: Pod deletion and recovery${NC}"
echo "Deleting a gateway pod..."
GATEWAY_POD=$(kubectl get pod -n app -l app=gateway -o jsonpath="{.items[0].metadata.name}")
kubectl delete pod -n app $GATEWAY_POD

echo "Waiting for pod recovery..."
sleep 10

if kubectl get pod -n app -l app=gateway | grep -q Running; then
    echo -e "${GREEN}✓ Gateway pod recovered successfully${NC}"
else
    echo -e "${RED}✗ Gateway pod failed to recover${NC}"
fi

# Test 2: Simulate high CPU usage
echo -e "\n${YELLOW}Test 2: Simulating high CPU usage${NC}"
echo "Running CPU stress test on auth-service..."
AUTH_POD=$(kubectl get pod -n app -l app=auth-service -o jsonpath="{.items[0].metadata.name}")
# Use a simple loop to generate CPU load instead of stress command
kubectl exec -n app $AUTH_POD -- sh -c 'for i in $(seq 1 1000000); do echo $i > /dev/null; done' || echo "CPU test completed"

echo "Checking CPU metrics..."
sleep 5
if kubectl top pod -n app -l app=auth-service | grep -q "auth-service"; then
    echo -e "${GREEN}✓ CPU metrics are being collected${NC}"
else
    echo -e "${RED}✗ CPU metrics collection failed${NC}"
fi

# Test 3: Test network policy enforcement
echo -e "\n${YELLOW}Test 3: Network policy enforcement${NC}"
echo "Testing unauthorized access from auth-service to MinIO..."
if kubectl exec -n app $AUTH_POD -- curl -s -o /dev/null -w "%{http_code}" http://minio.minio:9000/minio/health/live | grep -q "200"; then
    echo -e "${RED}✗ Network policy failed: auth-service can access MinIO${NC}"
else
    echo -e "${GREEN}✓ Network policy working: auth-service cannot access MinIO${NC}"
fi

# Test 4: Verify monitoring alerts
echo -e "\n${YELLOW}Test 4: Checking monitoring alerts${NC}"
echo "Checking Prometheus rules..."
if kubectl get prometheusrules -n monitoring | grep -q "microservices-alerts"; then
    echo -e "${GREEN}✓ Alert rules are configured${NC}"
else
    echo -e "${RED}✗ Alert rules are missing${NC}"
fi
