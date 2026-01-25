# 🚀 Inception of Things

> A 42 Network project that combines **Docker, Kubernetes (K3s/K3d), Vagrant, Argo CD, and GitOps** to automate the deployment and management of containerized applications on a cluster. It enhances networking and orchestration skills beyond the classic Inception (Docker LEMP stack) subject, introducing infrastructure automation and continuous deployment.

---

## 📘 About the Project

**Inception of Things** is a duo project within the 42 Network curriculum that teaches advanced system administration and infrastructure automation. The project is designed to guide you through:

- Setting up **multi‑node environments** using Virtual Machines (Vagrant)
- Deploying and managing a **lightweight Kubernetes cluster** (K3s or K3d)
- Running applications on a Kubernetes cluster
- Using **Argo CD** for GitOps‑style continuous deployment
- (Bonus) Integrating GitLab CI/CD for automated deployments

This project builds real skills in container orchestration, networking, automation, infrastructure as code (IaC), and CI/CD workflows.

### Key Milestones:
- **Part 1:** K3s Cluster with Vagrant (multi-node setup)
- **Part 2:** K3s Networking & Application Deployment (Ingress routing)
- **Part 3:** K3d & GitOps with Argo CD (automated sync)
- **Bonus:** GitLab CI/CD & Private Registry (self-hosted ecosystem)

---

## 🧩 Core Technologies

|     Technology      | Purpose |
|---------------------|---------|
| **Vagrant**         | Creates reproducible virtual machines for development |
| **K3s / K3d**       | Lightweight Kubernetes distribution for cluster orchestration |
| **Docker**          | Builds and runs containerized applications |
| **Argo CD**         | GitOps tool for declarative continuous deployment |
| **GitHub / GitLab** | Hosts source code and deployment configurations |
| **kubectl**         | Kubernetes command‑line tool for cluster interaction |
| **Helm**            | Package manager for Kubernetes applications |

---

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **Vagrant** (v2.2+) with a hypervisor (VirtualBox, KVM, etc.)
- Sufficient resources: **8GB+ RAM**, **20GB+ disk space**

> **Note:** Docker, kubectl, and git are installed automatically via the setup scripts in each part.

---

## 🚀 Project Goals

This project helps you learn to:

- ⚙️ Build and configure **multi‑node clusters** with Vagrant and Kubernetes
- 📦 Deploy applications using **containers and Kubernetes resources**
- 🔄 Automate deployment with **Argo CD** using a GitOps workflow
- 🔐 Understand cluster networking, namespaces, and service routing
- 💻 Explore **CI/CD pipelines** (GitLab or GitHub Actions) for automated deployments
- 🏗️ Implement Infrastructure as Code (IaC) principles

---

## � Project Structure

```
IoT/
├── p1/                    # Part 1: K3s with Vagrant
│   ├── Vagrantfile
│   └── scripts/
│       ├── MasterSetup.sh
│       └── WorkerSetup.sh
├── p2/                    # Part 2: K3s Networking & Deployments
│   ├── Vagrantfile
│   ├── confs/            # Kubernetes manifests
│   │   ├── app1-deployment.yaml
│   │   ├── app1-service.yaml
│   │   ├── apps-ingress.yaml
│   │   └── ...
│   └── scripts/
│       └── ServerSetup.sh
├── p3/                    # Part 3: K3d & Argo CD
│   ├── confs/
│   │   ├── application.yaml
│   │   └── argocd-cm.yaml
│   └── scripts/
│       ├── cleanup-k3d.sh
│       └── deploy-cluster.sh
├── bonus/                 # Bonus: GitLab CI/CD
│   ├── confs/
│   │   ├── application.yaml
│   │   └── argocd-cm.yaml
│   └── scripts/
│       ├── clean-cluster.sh
│       └── deploy-cluster.sh
└── README.md
```

---

## 🚀 Getting Started by Part

### ✅ Part 1: K3s Cluster with Vagrant
In this part, we set up a Controller (Server) and a Worker (Agent) node using Vagrant.

**Nodes:**
* **S-Node (Server):** Runs the K3s control plane.
* **SW-Node (Worker):** Connects to the server using a shared token.

**Quick Start:**
```bash
cd p1/
vagrant up
```

**Verification:**
```bash
# SSH into the server node and check cluster status
vagrant ssh S-Node
kubectl get nodes -o wide
```

**Cleanup:**
```bash
vagrant destroy -f
```

### 📦 Part 2: K3s Networking & App Deployment
Implementation of three web applications using K3s resources. This stage focuses on internal routing and external access via **Ingress**.

**Applications:**
* **App 1 & App 2:** Simple static pages
* **App 3:** A more complex service
* **Ingress:** Configured to route traffic based on host headers (e.g., `app1.com`)

**Kubernetes Resources:**
- Deployments (app1, app2, app3)
- Services (ClusterIP/NodePort)
- Ingress controller configuration

**Quick Start:**
```bash
cd p2/
vagrant up
vagrant ssh S-Node

# Apply all deployments
kubectl apply -f /vagrant/confs/

# Check resources
kubectl get deployments,services,ingress
```

**Testing Access:**
```bash
# Get the ingress IP and configure your /etc/hosts
kubectl get ingress
# Add to /etc/hosts:
# <INGRESS_IP> app1.com app2.com app3.com

# Test with curl
curl -H "Host: app1.com" http://<INGRESS_IP>
curl -H "Host: app2.com" http://<INGRESS_IP>
curl -H "Host: app3.com" http://<INGRESS_IP>

# Or if /etc/hosts is configured:
curl http://app1.com
curl http://app2.com
curl http://app3.com
```

---

### 🔄 Part 3: K3d & GitOps (Argo CD)
Transitioning to **K3d** (K3s in Docker) to manage a cluster locally and implementing **Argo CD** for automated syncing.

**Workflow:**
1. **Create a cluster** with K3d
2. **Install Argo CD** in the `argocd` namespace
3. **Deploy a Project** that tracks a GitHub repository
4. **Auto-sync:** Any change pushed to YAML files is instantly reflected in the cluster

**Quick Start:**
```bash
cd p3/

# Run the deployment script (creates cluster + installs Argo CD)
./scripts/deploy-cluster.sh
```

**Access Argo CD:**
```bash
# Access Argo CD UI at https://localhost:8080
# (Port forwarding is configured in the deployment script)

# Login credentials:
# Username: admin
# Password: incept123!
```

**Cleanup:**
```bash
./scripts/cleanup-k3d.sh
```

---

### 🌟 Bonus: GitLab CI/CD & Private Registry

The bonus part expands the GitOps workflow by hosting the entire ecosystem locally. This involves deploying a full **GitLab** instance within the cluster to replace external providers like GitHub.

**Requirements:**
* **Local Instance:** GitLab must run locally within the cluster (not on gitlab.com)
* **Dedicated Namespace:** All GitLab components isolated in the `gitlab` namespace
* **Compatibility:** All Part 3 GitOps functionality (Argo CD auto-sync) must work seamlessly with local GitLab
* **Tools:** Usage of **Helm** is permitted and recommended for complex deployments

**Deployment Flow:**
1. **Deploy GitLab:** Use Helm charts to install GitLab (Community Edition) into the `gitlab` namespace
2. **Configure Access:** Set up local DNS or host mapping to access the GitLab UI
3. **Migrate GitOps:** Move application manifests from GitHub to local GitLab repository
4. **Connect Argo CD:** Update Argo CD secrets and repository settings to pull from local GitLab URL

**Quick Start:**
```bash
cd bonus/

# Deploy the cluster and all services
./scripts/deploy-cluster.sh

# Verify GitLab is running
kubectl get deployments -n gitlab
```

**Cleanup:**
```bash
./scripts/clean-cluster.sh
```

---

## 🔧 Common Commands

### Cluster Management
```bash
# View nodes
kubectl get nodes -o wide

# View all resources
kubectl get all -A

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Describe a resource for debugging
kubectl describe pod <pod-name> -n <namespace>

# Apply/Delete manifests
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>
```

### Argo CD Management (Part 3+)
```bash
# List applications
kubectl get applications -n argocd

# Sync an application
argocd app sync <app-name>

# View sync status
argocd app get <app-name>
```

### Debugging
```bash
# Get pod events
kubectl describe pod <pod-name> -n <namespace>

# Check events in namespace
kubectl get events -n <namespace>

# Port-forward for local access
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace>
```

---

## 📚 Learning Resources

- **Kubernetes Official Docs:** https://kubernetes.io/docs/
- **K3s Documentation:** https://docs.k3s.io/
- **K3d Documentation:** https://k3d.io/
- **Argo CD Documentation:** https://argo-cd.readthedocs.io/
- **GitOps Principles:** https://www.gitops.tech/
- **Helm Documentation:** https://helm.sh/docs/

---

## 🛠️ Troubleshooting

### Vagrant Issues
- **Hypervisor not found:** Install VirtualBox or ensure your hypervisor is properly configured
- **Port conflicts:** Check if port 22 or other required ports are already in use
- **Network issues:** Ensure you have sufficient network configuration in your system

### Kubernetes Issues
- **Pods not starting:** Check pod logs with `kubectl logs <pod-name>`
- **Service connectivity:** Verify services are properly exposed with `kubectl get svc`
- **Ingress not working:** Ensure ingress controller is installed and routes are configured

### Argo CD Issues
- **App not syncing:** Check Argo CD logs: `kubectl logs deployment/argocd-application-controller -n argocd`
- **Repository access denied:** Verify credentials in ArgoCD and GitHub/GitLab settings
- **Port-forward issues:** Ensure port 8080 is available; use different port if needed

---

## 🤝 Contributing

This is a 42 Network curriculum project. Each team member should:
- Work on assigned parts
- Document your setup process
- Share learnings with the team
- Follow best practices for Kubernetes and CI/CD

---

## 📝 Notes

- Keep Vagrantfiles and scripts up-to-date for team consistency
- Document any customizations or changes made
- Test thoroughly before pushing to main branch
- Use meaningful commit messages for infrastructure changes

---

**Good luck with your Inception of Things project! 🚀**

---

