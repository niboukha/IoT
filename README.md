# Inception of Things

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


---

## 🚀 Project Goals

This project helps you learn to:

- ⚙️ Build and configure **multi‑node clusters** with Vagrant and Kubernetes  
- 📦 Deploy applications using **containers and Kubernetes resources**  
- 🔄 Automate deployment with **Argo CD** using a GitOps workflow  
- 🔐 Understand cluster networking, namespaces, and service routing  
- 💻 Explore **CI/CD pipelines** (GitLab or GitHub Actions) for automated deployments :contentReference[oaicite:3]{index=3}

---

## 🚀 Project Steps

### 🧱 Part 1: K3s Cluster with Vagrant
In this part, we set up a Controller (Server) and a Worker (Agent) node using Vagrant.

* **S-Node (Server):** Runs the K3s control plane.
* **SW-Node (Worker):** Connects to the server using a shared token.

```bash
# To launch the nodes
cd p1/
vagrant up

# To verify the cluster
kubectl get nodes -o wide
```

### 📦 Part 2: K3s Networking & App Deployment
Implementation of three web applications using K3s resources. This stage focuses on internal routing and external access via **Ingress**.



* **App 1 & App 2:** Simple static pages.
* **App 3:** A more complex service.
* **Ingress:** Configured to route traffic based on host headers (e.g., `app1.com`).

---

### 🔄 Part 3: K3d & GitOps (Argo CD)
Transitioning to **K3d** (K3s in Docker) to manage a cluster locally and implementing **Argo CD** for automated syncing.

1.  **Create a cluster** with K3d.
2.  **Install Argo CD** in the `argocd` namespace.
3.  **Deploy a "Project"** that tracks a GitHub repository.
4.  **Auto-sync:** Any change pushed to the YAML files in your repo is instantly reflected in the cluster.

---

### 🌟 Bonus: GitLab CI/CD & Private Registry

The bonus part expands the GitOps workflow by hosting the entire ecosystem locally. This involves deploying a full **GitLab** instance within the cluster to replace external providers like GitHub.


#### Requirements:
* **Local Instance:** GitLab must run locally within the cluster (not on gitlab.com).
* **Dedicated Namespace:** All GitLab components must be isolated in the `gitlab` namespace.
* **Compatibility:** All Part 3 GitOps functionality (Argo CD auto-sync) must work seamlessly using your local GitLab instance as the source of truth.
* **Tools:** Usage of **Helm** is permitted and recommended to manage the complex GitLab deployment.

#### Deployment Flow:
1.  **Deploy GitLab:** Use Helm charts to install GitLab (Core/Community Edition) into the `gitlab` namespace.
2.  **Configure Access:** Set up local DNS or host mapping to access the local GitLab UI.
3.  **Migrate GitOps:** Move your application manifests from GitHub to your local GitLab repository.
4.  **Connect Argo CD:** Update Argo CD cluster secrets and repository settings to pull from the local GitLab URL.

---

