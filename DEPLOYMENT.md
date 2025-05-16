# Microservices Deployment Guide

This guide walks through the deployment of a secure microservices stack using Kubernetes, including monitoring, network policies, and testing procedures.

## Prerequisites

- Minikube installed
- kubectl configured
- Helm installed
- Docker installed

## 1. Start Minikube with Calico CNI

```bash
minikube start --driver=docker --cni=calico
```

## 2. Create Required Namespaces

```bash
kubectl create namespace monitoring
kubectl create namespace app
kubectl create namespace minio
```

## 3. Deploy Monitoring Stack

```bash
# Install Prometheus and Grafana
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Create Prometheus alert rules
kubectl apply -f prometheus-rules.yaml
```

## 4. Deploy MinIO

```bash
# Deploy MinIO in the minio namespace
helm install minio ./helm-charts/minio -n minio

# Copy MinIO credentials to app namespace
kubectl get secret -n minio minio-credentials -o yaml | sed 's/namespace: minio/namespace: app/' | kubectl apply -f -
```

## 5. Deploy Application Stack

```bash
# Deploy the main application components
helm install app ./helm-charts/app -n app
helm install gateway ./helm-charts/gateway -n app
helm install auth-service ./helm-charts/auth-service -n app
helm install data-service ./helm-charts/data-service -n app
```

## 6. Create Debug Pods for Testing

```bash
# Create curl debug pod for testing
kubectl run curl-debug -n app --image=curlimages/curl:latest --labels="app=data-service" --restart=Never -- sleep infinity
```

## 7. Testing the Deployment

### Test MinIO Access

Run the MinIO access test script:
```bash
bash scripts/test-minio-access.sh
```

This script verifies:
- Data service can access MinIO
- Network policies are correctly enforced
- Unauthorized access is blocked

### Test Failure Scenarios

Run the failure simulation test script:
```bash
bash scripts/test-failures.sh
```

This script tests:
1. Pod deletion and recovery
2. CPU usage monitoring
3. Network policy enforcement
4. Monitoring alerts

## 8. Accessing Services

### Grafana Dashboard

The monitoring stack includes Grafana for visualizing metrics. To access the Grafana dashboard:

1. Set up port forwarding:
   ```bash
   kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
   ```

2. Access Grafana in your browser at http://localhost:3000

3. Login credentials:
   - Username: admin
   - Password: prom-operator (or get it using the command below)
   ```bash
   kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d
   ```

4. The Microservices Dashboard will be automatically loaded and shows:
   - HTTP Request Rate for all services
   - Error Rate for all services

The dashboard automatically refreshes every 5 seconds and shows data from the last 6 hours. You can adjust the time range using the time picker in the top right corner.

### Application Services
- Gateway: http://localhost:8080
- Auth Service: http://localhost:8081
- Data Service: http://localhost:8082

## 9. Network Policies

The deployment includes network policies that:
- Allow data-service to access MinIO
- Block auth-service from accessing MinIO
- Restrict inter-service communication as needed

## 10. Monitoring and Alerts

The monitoring stack includes:
- Prometheus for metrics collection
- Grafana for visualization
- Alert rules for:
  - High CPU usage
  - Pod failures
  - Service availability

## 11. OPA Policies

The deployment includes Open Policy Agent (OPA) policies that enforce:

1. Resource Requirements:
   - All containers must have resource limits defined
   - All deployments must have the 'app' label

2. Security Context:
   - Containers must run as non-root
   - Root filesystem must be read-only
   - Privilege escalation must be disabled

To apply the OPA policies:
```bash
kubectl apply -f policies/opa/policy-configmap.yaml
```

These policies help ensure:
- Resource management
- Security best practices
- Consistent labeling
- Container security

## Troubleshooting

1. If pods fail to start:
   ```bash
   kubectl describe pod -n <namespace> <pod-name>
   kubectl logs -n <namespace> <pod-name>
   ```

2. If network policies aren't working:
   ```bash
   kubectl get networkpolicies -n app
   kubectl describe networkpolicy -n app <policy-name>
   ```

3. If monitoring isn't working:
   ```bash
   kubectl get pods -n monitoring
   kubectl get prometheusrules -n monitoring
   ```

## Cleanup

To remove all deployed resources:
```bash
helm uninstall monitoring -n monitoring
helm uninstall app gateway auth-service data-service -n app
helm uninstall minio -n minio
kubectl delete namespace monitoring app minio
``` 