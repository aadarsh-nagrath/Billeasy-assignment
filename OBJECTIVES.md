# DevOps Assignment Objectives and Progress

## 🎯 Overall Objective
Build and secure a local Kubernetes microservices environment that mimics AWS EKS production patterns, using Minikube, and respond to a simulated production incident involving a security leak and network policy violations.

## 📋 Progress Tracking

### Part 1: Microservice Stack
- [x] Deploy three services using Helm
  - [x] gateway (nginxdemos/hello)
  - [x] auth-service (kennethreitz/httpbin)
  - [x] data-service (hashicorp/http-echo)
- [x] Implement containerized deployment using Helm
- [x] Configure liveness/readiness probes
- [x] Set proper resource requests/limits
- [x] Configure ingress for gateway service
- [x] Implement internal-only access for auth-service and data-service
- [x] Create separate namespaces for system and application

### Part 2: IAM Simulation with MinIO
- [x] Deploy MinIO in the cluster
- [x] Create Secret for MinIO credentials
- [x] Create ServiceAccount for data-service
- [x] Implement access control policies
- [x] Verify access permissions
  - [x] Confirm data-service can access bucket
  - [x] Verify auth-service cannot access bucket
- [x] (Optional) Implement OPA/Kyverno policies

### Part 3: Security Incident Response
- [x] Investigate header leakage issue
- [x] Fix sensitive header logging
- [x] Implement NetworkPolicy
  - [x] Restrict auth-service to data-service communication
  - [x] Block unnecessary egress traffic
- [x] Implement preventive measures
  - [x] Set up OPA/Kyverno/Falco for header logging detection
  - [x] Configure alerts for policy violations

### Part 4: Observability
- [x] Install Prometheus & Grafana
- [x] Create Grafana dashboards for:
  - [x] Pod CPU/memory usage
  - [x] HTTP request rates and errors
  - [x] Pod restarts
- [x] Set up alerts for:
  - [x] Abnormal restarts
  - [x] Failed probes
  - [x] High error rates
  - [x] Resource pressure

### Part 5: Failure Simulation
- [x] Simulate pod failure
- [x] Verify system recovery
- [x] Document observability during failure
- [x] Test HPA/ReplicaSet behavior

## 🏗️ Architecture Components
- Minikube cluster with ingress and metrics-server
- NGINX Ingress Controller
- Prometheus & Grafana stack
- Microservices architecture
- MinIO for S3 simulation
- Network policies and security controls

## 📊 Success Metrics
- All services deployed and accessible as required
- Security policies properly enforced
- Observability stack providing meaningful insights
- System able to recover from failures
- Documentation complete and clear

## 🔄 Next Steps
1. Test MinIO access permissions
2. Simulate failures and verify recovery
3. Document the entire setup
4. Final testing and validation 