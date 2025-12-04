# CICD-Actions

CI/CD example using GitHub Actions and Terraform to provision AWS infrastructure.  
The project runs automated Terraform workflows for validation, planning, applying changes, and manual destruction.

## GitHub Actions workflows

- **Pull Request checks**  
  Runs `terraform fmt -check`, `terraform init`, and `terraform plan` on every PR to `main`.  
  Fails the PR if formatting or plan validation fails.

- **Apply on merge**  
  Automatically runs `terraform apply` when changes are merged into `main`.

- **Manual destroy**  
  Workflow triggered via `workflow_dispatch` to run `terraform destroy` and clean up all resources.

## Secrets required

Set the following in GitHub → Settings → Secrets → Actions:

- `AWS_ACCESS_KEY_ID`  
- `AWS_SECRET_ACCESS_KEY`  
- `AWS_SESSION_TOKEN`  
- `AWS_DEFAULT_REGION` (eu-west-1)

## Purpose

This repository demonstrates a simple CI/CD pipeline integrating GitHub Actions with Terraform to manage AWS infrastructure in an automated way.
