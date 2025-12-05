# CICD-Actions

CI/CD pipeline using GitHub Actions and Terraform to provision, update, and destroy AWS infrastructure.  
The project validates all Terraform changes on pull requests, automatically applies them after merge, and offers a manual destroy workflow.  
Terraform state is stored remotely in S3 with DynamoDB locking.

---

## 📦 Infrastructure

Using Terraform, the following resources are deployed in **AWS eu-central-1**:

- VPC with public and private subnets  
- NAT Gateway + Internet Gateway  
- Application Load Balancer (ALB)  
- Two Auto Scaling Groups (Foo / Bar)  
- Bastion EC2 instance  
- Security groups, route tables, target groups, etc.

**Remote state backend:**

- S3 Bucket: `andreis-tf-state-cicd-actions`  
- DynamoDB Table: `terraform-locks`  
  → Enables state locking during apply/destroy.

---

## 🤖 GitHub Actions Workflows

### **1. Pull Request Checks (PR → main)**  
File: `pr-checks.yml`  
Automatically runs on every pull request targeting `main`:

- `terraform fmt -check`  
- `terraform init`  
- `terraform plan`

Plan must pass to allow merge (required branch protection rule).

---

### **2. Apply on Merge (push → main)**  
File: `apply-on-main.yml`  
Triggered when changes are merged into `main`:

- Initializes Terraform with remote backend  
- Runs `terraform apply -auto-approve`  
- Updates the shared state in S3  
- Uses DynamoDB locking to prevent concurrent runs

This ensures the `main` branch automatically deploys real infrastructure.

---

### **3. Manual Destroy**  
File: `destroy.yml`  
Triggered manually via **workflow_dispatch**:

- Runs `terraform init`  
- Executes `terraform destroy -auto-approve` using the same remote state  
- Cleans up all Terraform-managed resources

---

## 🔐 GitHub Secrets Required

Set these in **GitHub → Settings → Secrets → Actions**  
(temporary AWS credentials that must be refreshed periodically):

- `AWS_ACCESS_KEY_ID`  
- `AWS_SECRET_ACCESS_KEY`  
- `AWS_SESSION_TOKEN`  
- *(all used by `configure-aws-credentials@v4` in each workflow)*

---

## 🎯 Why run checks before merging?

Pull Request checks ensure that:

- Terraform code is valid and correctly formatted  
- Infrastructure changes are visible via `terraform plan`  
- Breaking or unsafe changes cannot be merged  
- The `main` branch remains deployable at all times  

This enforces safe Infrastructure-as-Code practices.

---

## 🧩 Purpose

This repository demonstrates a full CI/CD pipeline for Terraform:

- PR validation  
- Automatic apply on merge  
- Manual destroy  
- S3 remote backend with DynamoDB locking  
- End-to-end automation for production-style IaC workflows.

