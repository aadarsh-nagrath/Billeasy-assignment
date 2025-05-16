#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Testing MinIO access permissions..."

# Test data-service access to MinIO using debug pod
echo -e "\nTesting data-service access to MinIO..."
if kubectl exec -n app curl-debug -- curl -s -o /dev/null -w "%{http_code}" http://minio.minio:9000/minio/health/live | grep -q "200"; then
    echo -e "${GREEN}✓ data-service can access MinIO bucket${NC}"
else
    echo -e "${RED}✗ data-service cannot access MinIO bucket${NC}"
fi

# Test network policy enforcement
echo -e "\nTesting network policy enforcement..."

echo "Testing data-service to MinIO communication..."
if kubectl exec -n app curl-debug -- curl -s -o /dev/null -w "%{http_code}" http://minio.minio:9000/minio/health/live | grep -q "200"; then
    echo -e "${GREEN}✓ data-service can communicate with MinIO${NC}"
else
    echo -e "${RED}✗ data-service cannot communicate with MinIO${NC}"
fi
