# EKS Node App — Architecture & Technical Documentation

## Table of Contents
1. [Infrastructure Architecture (Terraform)](#1-infrastructure-architecture-terraform)
2. [Terraform Resource Dependency Graph](#2-terraform-resource-dependency-graph)
3. [Kubernetes Architecture](#3-kubernetes-architecture)
4. [CI/CD Pipeline Architecture](#4-cicd-pipeline-architecture)
5. [End-to-End Flow](#5-end-to-end-flow)
6. [Terraform Module Structure](#6-terraform-module-structure)
7. [Dependency Ordering (Apply & Destroy)](#7-dependency-ordering-apply--destroy)

---

## 1. Infrastructure Architecture (Terraform)

```
AWS Account (922344941106) — Region: us-east-1
│
└── VPC: eks-vpc-dev  (10.1.0.0/16)
    │
    ├── Internet Gateway (eks-igw-dev)
    │   └── attached to VPC
    │
    ├── Availability Zone: us-east-1a
    │   ├── Public Subnet-1  (10.1.1.0/24)  [map_public_ip_on_launch=true]
    │   │   ├── Route Table: Public RT  →  0.0.0.0/0 → IGW
    │   │   └── NAT Gateway (eks-nat-dev)
    │   │       └── Elastic IP (eks-nat-eip-dev)
    │   │
    │   └── Private Subnet-1  (10.1.3.0/24)
    │       ├── Route Table: Private RT  →  0.0.0.0/0 → NAT GW
    │       └── EKS Node Group EC2s (t3.small)
    │
    └── Availability Zone: us-east-1b
        ├── Public Subnet-2  (10.1.2.0/24)  [map_public_ip_on_launch=true]
        │   └── Route Table: Public RT  →  0.0.0.0/0 → IGW
        │
        └── Private Subnet-2  (10.1.4.0/24)
            ├── Route Table: Private RT  →  0.0.0.0/0 → NAT GW
            └── EKS Node Group EC2s (t3.small)
```

---

## 2. Terraform Resource Dependency Graph

> Resources are listed in **creation order** (destroy is the reverse).
> Arrows (`→`) mean "depends on" / "must exist before".

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          MODULE: networks                                    │
│                                                                              │
│   aws_vpc.main                                                               │
│       │                                                                      │
│       ├──► aws_subnet.subnet-public-1  ──────────────────────────────┐      │
│       ├──► aws_subnet.subnet-public-2                                │      │
│       ├──► aws_subnet.subnet-private-1                               │      │
│       ├──► aws_subnet.subnet-private-2                               │      │
│       │                                                              │      │
│       └──► aws_internet_gateway.main                                 │      │
│                   │                                                  │      │
│                   ├──► aws_eip.nat                                   │      │
│                   │         │                                        │      │
│                   │         └──► aws_nat_gateway.main ◄──────────────┘      │
│                   │                      │                                   │
│                   │                      │                                   │
│                   ▼                      ▼                                   │
│       aws_route_table.public   aws_route_table.private                       │
│       (0.0.0.0/0 → IGW)        (0.0.0.0/0 → NAT GW)                        │
│               │                         │                                   │
│               ├──► RT assoc: public-1   ├──► RT assoc: private-1            │
│               └──► RT assoc: public-2   └──► RT assoc: private-2            │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                    │ outputs: public_subnet_ids,
                    │         private_subnet_ids,
                    │         nat_gateway_id, vpc_id
                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            MODULE: iam                                       │
│                                                                              │
│   aws_iam_role.eks_cluster_role                                              │
│       └──► aws_iam_role_policy_attachment  (AmazonEKSClusterPolicy)         │
│                                                                              │
│   aws_iam_role.eks_nodegroup_role                                            │
│       ├──► aws_iam_role_policy_attachment  (AmazonEKSWorkerNodePolicy)      │
│       ├──► aws_iam_role_policy_attachment  (AmazonEKS_CNI_Policy)           │
│       └──► aws_iam_role_policy_attachment  (AmazonEC2ContainerRegistryRO)   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                    │ outputs: iam_role_arn,
                    │         nodegroup_role_arn
                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            MODULE: eks                                       │
│         depends_on: [module.networks]                                        │
│                                                                              │
│   aws_eks_cluster.main                                                       │
│       ├── role_arn         ◄── module.iam.iam_role_arn                       │
│       ├── subnet_ids       ◄── public_subnet_ids + private_subnet_ids        │
│       ├── NatGatewayDep    ◄── module.networks.nat_gateway_id  (dep chain)   │
│       └── endpoint: private=true, public=true                                │
│                   │                                                          │
│                   └──► aws_eks_node_group.name                               │
│                             ├── node_role_arn  ◄── module.iam.nodegroup_arn  │
│                             ├── subnet_ids     ◄── private_subnet_ids only   │
│                             ├── instance_type: t3.small                      │
│                             ├── desired: 2 / min: 1 / max: 3                 │
│                             ├── capacity_type: ON_DEMAND                     │
│                             └── disk_size: 20 GB                             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                    │ outputs: cluster_name,
                    │         cluster_endpoint,
                    │         cluster_certificate_authority
                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         MODULE: eks-access                                   │
│         depends_on: [module.eks]                                             │
│                                                                              │
│   aws_eks_access_entry.eks-admin-access    (for_each admin ARN)              │
│       └──► aws_eks_access_policy_association.eks-admin-policy                │
│               └── policy: AmazonEKSClusterAdminPolicy                        │
│               └── admin ARNs:                                                │
│                     - arn:aws:iam::922344941106:user/mahin                   │
│                     - arn:aws:iam::922344941106:role/github-actions-role     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Kubernetes Architecture

```
EKS Cluster: tf-eks-cluster-dev
│
├── Authentication: API_AND_CONFIG_MAP
├── Kubernetes v1.33
├── Endpoint: Public + Private access
│
└── Namespace: nodejs-app-namespace
    │
    ├── Deployment: nodejs-app
    │   ├── Image: docker.io/mahin96/eks-node-app-project:<tag>
    │   ├── Port: 3000 (containerPort)
    │   ├── Replicas: 1 (base, controlled by HPA)
    │   ├── Resources:
    │   │   ├── requests: 50m CPU / 64Mi RAM
    │   │   └── limits:  200m CPU / 128Mi RAM
    │   └── Probes: livenessProbe + readinessProbe
    │
    ├── Service: nodejs-app (LoadBalancer)
    │   ├── port: 80  →  targetPort: 3000
    │   └── Creates AWS Classic/NLB ELB (maps public IP → triggers IGW dependency)
    │
    └── HorizontalPodAutoscaler: nodejs-app
        ├── minReplicas: 1
        ├── maxReplicas: 20
        ├── CPU    scale-up threshold: 85%
        └── Memory scale-up threshold: 90%

Node Group (EC2 in private subnets)
    ├── t3.small  ON_DEMAND
    ├── desired: 2 nodes / min: 1 / max: 3
    ├── Traffic from Pods: outbound via NAT Gateway
    └── Traffic to Pods: inbound via LoadBalancer → IGW → ELB → NodePort
```

---

## 4. CI/CD Pipeline Architecture

> GitHub Actions workflows manage Terraform infrastructure provisioning
> and application deployment to EKS.

```
GitHub Repository
│
├── push / pull_request
│
├── ─────────────────────────────────────────────────────────────
│   PIPELINE 1: Terraform Infrastructure (terraform-apply / destroy)
│   ─────────────────────────────────────────────────────────────
│
│   Trigger: manual workflow_dispatch OR push to main
│       │
│       ├── 1. Checkout code
│       ├── 2. Configure AWS Credentials
│       │       └── Role: arn:aws:iam::922344941106:role/github-actions-role
│       ├── 3. terraform init
│       │       └── Backend: S3 → eks-node-app-project-tf-bucket
│       │                     key: eks/terraform.tfstate  (us-east-1)
│       ├── 4. terraform validate / fmt check
│       ├── 5. terraform plan
│       └── 6. terraform apply / destroy
│               └── Module order enforced by depends_on:
│                   networks → iam → eks → eks-access
│
├── ─────────────────────────────────────────────────────────────
│   PIPELINE 2: App Build & Push (docker-build-push)
│   ─────────────────────────────────────────────────────────────
│
│   Trigger: push to main (app code changes)
│       │
│       ├── 1. Checkout code
│       ├── 2. Docker login → docker.io (mahin96)
│       ├── 3. docker build -t mahin96/eks-node-app-project:<sha>
│       │       └── Dockerfile: node:18-alpine, EXPOSE 3000, CMD node index.js
│       └── 4. docker push → docker.io/mahin96/eks-node-app-project:<sha>
│
├── ─────────────────────────────────────────────────────────────
│   PIPELINE 3: App Deploy to EKS (helmfile-deploy)
│   ─────────────────────────────────────────────────────────────
│
│   Trigger: after docker-build-push succeeds (workflow_run)
│       │
│       ├── 1. Configure AWS Credentials
│       ├── 2. aws eks update-kubeconfig --name tf-eks-cluster-dev
│       ├── 3. helmfile apply
│       │       ├── chart: deployment/chart
│       │       ├── values: deployment/values/app.yaml
│       │       └── set: image.tag=<git-sha>
│       └── 4. Kubernetes applies:
│               ├── Deployment (rolling update)
│               ├── Service (LoadBalancer)
│               └── HPA (auto-scaling)
│
└── ─────────────────────────────────────────────────────────────
    PIPELINE 4: OIDC Destroy (terraform-destroy-oidc)
    ─────────────────────────────────────────────────────────────

    Trigger: manual workflow_dispatch
        │
        ├── 1. Configure AWS via OIDC  (github-actions-role)
        ├── 2. terraform init (S3 backend)
        ├── 3. terraform destroy -auto-approve
        │       └── Enforced destroy order:
        │           eks-access → eks (node group + cluster) → networks
        │           (NAT GW → EIP → IGW → subnets → VPC)
        └── 4. State removed from S3
```

---

## 5. End-to-End Flow

```
Developer
    │
    │  git push
    ▼
GitHub Repository
    │
    ├──────────────────────────────────────────────────────┐
    │  (first time / infra change)                         │  (app code change)
    ▼                                                      ▼
Pipeline 1: Terraform Apply                     Pipeline 2: Docker Build & Push
    │                                                      │
    │  Provisions:                                         │  docker.io/mahin96/
    │  VPC, Subnets, IGW, NAT,                            │  eks-node-app-project:<sha>
    │  Route Tables, IAM Roles,                            │
    │  EKS Cluster, Node Group,                            │
    │  EKS Access Entries                                  │
    │                                                      │
    └──────────────────────┬───────────────────────────────┘
                           │
                           ▼
                 Pipeline 3: Helmfile Deploy
                           │
                     aws eks update-kubeconfig
                           │
                     helmfile apply (image.tag=<sha>)
                           │
                 ┌─────────┴──────────────┐
                 ▼                        ▼
         Kubernetes Deployment      Kubernetes HPA
         Rolling Update             (cpu: 85%, mem: 90%)
                 │                        │
                 ▼                        ▼
         Pods on EC2 Nodes          1–20 replicas
         (private subnets)          auto-scaled
                 │
                 ▼
         Service: LoadBalancer
                 │
         AWS ELB (public IP)
                 │
         Internet → IGW → ELB → NodePort → Pod:3000
                 │
                 ▼
           GET /          → { "message": "Hello from Node.js..." }
           GET /health    → "OK"
```

---

## 6. Terraform Module Structure

```
terraform/
│
├── environments/
│   └── dev/
│       ├── main.tf          # Root module — wires all child modules together
│       │                      Backend: S3 (eks-node-app-project-tf-bucket)
│       ├── variables.tf     # Declares all input variables
│       ├── terraform.tfvars # Dev environment values (region, CIDRs, etc.)
│       └── outputs.tf       # Exposed outputs for the dev environment
│
└── modules/
    ├── networks/            # VPC, Subnets, IGW, NAT GW, EIP, Route Tables
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf       # vpc_id, subnet IDs, nat_gateway_id, rt IDs
    │
    ├── iam/                 # IAM Roles & Policy Attachments for EKS
    │   ├── main.tf          # eks_cluster_role + eks_nodegroup_role
    │   ├── variables.tf
    │   └── outputs.tf       # iam_role_arn, nodegroup_role_arn
    │
    ├── eks/                 # EKS Cluster + Node Group
    │   ├── main.tf          # aws_eks_cluster + aws_eks_node_group
    │   ├── variables.tf     # Includes nat_gateway_id (dep chain variable)
    │   └── outputs.tf       # cluster_name, cluster_endpoint, cluster_arn
    │
    └── eks-access/          # EKS Access Entries (RBAC via API)
        ├── main.tf          # aws_eks_access_entry + policy_association
        ├── variables.tf
        └── outputs.tf
```

### Module Wiring (Input/Output Flow)

```
                   ┌──────────────┐
                   │   networks   │
                   └──────┬───────┘
                          │  public_subnet_ids
                          │  private_subnet_ids
                          │  nat_gateway_id
                          │  vpc_id
                          ▼
        ┌──────────┐    ┌─────────────┐
        │   iam    │───►│     eks     │
        └──────────┘    └──────┬──────┘
          iam_role_arn         │  cluster_name
          nodegroup_role_arn   │  cluster_endpoint
                               ▼
                       ┌──────────────┐
                       │  eks-access  │
                       └──────────────┘
```

---

## 7. Dependency Ordering (Apply & Destroy)

### Apply Order
```
1. networks   → VPC, subnets, IGW, EIP, NAT GW, route tables
2. iam        → IAM roles and policy attachments  (parallel with networks)
3. eks        → EKS cluster and node group        (waits for networks + iam)
4. eks-access → Access entries and policy assocs  (waits for eks)
```

### Destroy Order (Reverse)
```
1. eks-access → Remove access entries / policies
2. eks        → Drain + delete node group, then delete cluster
                (releases all ENIs from subnets)
3. networks   → In order:
                 a. Route table associations
                 b. Route tables
                 c. NAT Gateway  (releases EIP → unmaps public address)
                 d. EIP
                 e. Internet Gateway  (can now detach cleanly)
                 f. Subnets            (no more ENI dependencies)
                 g. VPC
```

### Key Dependency Rules Enforced in Code

| Resource                | Depends On                             | Why                                          |
|------------------------|----------------------------------------|----------------------------------------------|
| `aws_eip.nat`          | `aws_internet_gateway.main`            | IGW must exist before EIP is useful          |
| `aws_nat_gateway.main` | `aws_internet_gateway.main`, subnets   | Needs IGW + subnet to be ready               |
| `aws_route_table.public` | `aws_internet_gateway.main`          | Routes traffic through IGW                   |
| `aws_route_table.private` | `aws_nat_gateway.main`             | Routes traffic through NAT                   |
| `module.eks`           | `module.networks`                      | Needs VPC/subnets; ensures EKS destroyed first |
| `module.eks-access`    | `module.eks`                           | Cluster must exist; destroyed before cluster |
| `eks_cluster` tag      | `nat_gateway_id` var                   | Creates Terraform dep chain via tag reference |

---

## 8. State & Secrets Management

| Item                  | Location                                             |
|-----------------------|------------------------------------------------------|
| Terraform State       | S3: `eks-node-app-project-tf-bucket/eks/terraform.tfstate` |
| AWS Auth (CI)         | OIDC → `github-actions-role` (no long-lived keys)    |
| Docker Registry       | Docker Hub: `mahin96/eks-node-app-project`           |
| Kubernetes Auth (CI)  | `aws eks update-kubeconfig` via OIDC role            |
| EKS Admin Access      | IAM user `mahin` + `github-actions-role` via EKS API |
