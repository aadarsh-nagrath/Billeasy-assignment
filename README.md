# Secure Microservices Deployment with Minikube

This project demonstrates a secure microservices deployment in a local Kubernetes cluster using Minikube, simulating AWS EKS production patterns. The implementation focuses on security, observability, and incident response.

## Architecture

```
                                    [Internet]
                                         │
                                         ▼
                                    [Ingress]
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────┐
│                         App Namespace                        │
│  ┌──────────┐    ┌─────────────┐    ┌──────────────┐        │
│  │ Gateway  │◄───┤ Auth Service│◄───┤ Data Service │        │
│  └──────────┘    └─────────────┘    └──────────────┘        │
└─────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────┐
│                        MinIO Namespace                       │
│                     ┌──────────────────┐                    │
│                     │      MinIO       │                    │
│                     └──────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     Monitoring Namespace                     │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────────┐     │
│  │ Prometheus  │    │  Grafana    │    │ AlertManager │     │
│  └─────────────┘    └─────────────┘    └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Minikube
- Docker
- kubectl
- Helm
- (Optional) k9s, OPA, Kyverno, Falco

## Setup Instructions

1. Start Minikube with required resources:
   ```bash
   minikube start --cpus=2 --memory=4096 --addons=ingress,metrics-server
   ```

2. Install the monitoring stack:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install monitoring prometheus-community/kube-prometheus-stack
   ```

3. Deploy the microservices:
   ```bash
   # Deploy MinIO
   helm install minio ./helm-charts/minio
   
   # Deploy the application stack
   helm install app ./helm-charts/app
   ```

## Security Implementation

### Network Policies
- Gateway: Allows ingress traffic from internet and egress to auth-service
- Auth Service: Allows ingress from gateway and egress to data-service
- Data Service: Allows ingress from auth-service and egress to MinIO
- MinIO: Allows ingress only from data-service

### IAM Simulation
- MinIO credentials stored in Kubernetes secrets
- ServiceAccount bound to data-service for MinIO access
- Network policies enforce access control
- OPA policies prevent unauthorized access

### Security Incident Response
1. **Issue**: Auth-service leaking Authorization headers and unauthorized access
2. **Investigation**: 
   - Used kubectl logs to identify header leakage
   - Network policy violations detected
3. **Resolution**:
   - Updated deployment to filter sensitive headers
   - Implemented strict network policies
   - Added OPA policies for runtime enforcement

## Observability

### Monitoring Stack
- Prometheus for metrics collection
- Grafana for visualization
- AlertManager for alerting

### Key Metrics
- Pod CPU/memory usage
- HTTP request rates and errors
- Pod restarts
- Network policy violations

### Alerts
- High error rates (>5% over 5 minutes)
- Pod restarts
- Resource usage thresholds (85% CPU/memory)
- Network policy violations

## Testing

### Access Control Tests
```bash
./scripts/test-minio-access.sh
```
Tests:
- Data-service access to MinIO
- Auth-service access restrictions
- Network policy enforcement

### Failure Simulation
```bash
./scripts/test-failures.sh
```
Tests:
- Pod deletion and recovery
- Node pressure handling
- Network policy enforcement
- Monitoring verification
- Alert verification

## Design Decisions

1. **Namespace Separation**
   - App, MinIO, and Monitoring in separate namespaces
   - Improved security and resource isolation

2. **Network Policies**
   - Zero-trust approach
   - Explicit allow rules only
   - No default egress allowed

3. **Monitoring**
   - Prometheus for metrics
   - Grafana for visualization
   - AlertManager for notifications

4. **Security**
   - ServiceAccounts for service identity
   - Network policies for access control
   - OPA for policy enforcement

## Known Issues and Limitations

1. Local development environment limitations
   - Minikube resource constraints
   - Limited scalability testing

2. Security considerations
   - Basic authentication only
   - No TLS between services (local cluster)

