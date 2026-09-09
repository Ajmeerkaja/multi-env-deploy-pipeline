# multi-env-deploy-pipeline

# Automated Multi-Environment Deployment Pipeline

An end-to-end CI/CD pipeline that automatically builds, tests, and deploys a containerized Flask application across isolated Dev and Production environments on AWS, with a manual approval gate before production releases.

## Architecture

GitHub (push)
→ Jenkins (Checkout)
→ Docker (Build image)
→ Amazon ECR (Push image)
→ Ansible (Deploy to Dev EC2)
→ Manual Approval Gate
→ Ansible (Deploy to Prod EC2)



**Infrastructure provisioned via Terraform:**
- Dev EC2 instance (t2.micro)
- Prod EC2 instance (t2.micro)
- Jenkins EC2 instance (t2.medium)
- Security groups, SSH key pairs, CloudWatch CPU alarms — all generated per environment from a single reusable Terraform module

## Tech Stack

| Layer | Tool |
|---|---|
| Source Control | GitHub |
| CI/CD Orchestration | Jenkins (Pipeline as Code) |
| Containerization | Docker |
| Image Registry | Amazon ECR |
| Infrastructure as Code | Terraform |
| Configuration Management | Ansible |
| Monitoring | Amazon CloudWatch |
| Cloud Provider | AWS (EC2, ECR, IAM, CloudWatch) |

## How It Works

1. **Terraform** provisions three EC2 instances (Dev, Prod, Jenkins) from a single reusable module — each environment differs only in its input variables (name, instance size), demonstrating true infrastructure reusability.
2. **Ansible** configures each server: installs Docker, AWS CLI, and (on Jenkins) Jenkins itself — turning bare EC2 instances into ready-to-use environments without manual setup.
3. **Jenkins** watches the GitHub repository. On every push to `main`, it automatically:
   - Builds a new Docker image from the Flask app
   - Pushes the image to Amazon ECR, tagged with both the build number and `latest`
   - Runs the Ansible playbook to deploy the new image to the **Dev** server
   - **Pauses and waits for manual approval** before touching production
   - Once approved, runs the same Ansible playbook against the **Prod** server
4. The **same Docker image and Ansible playbook** are used for both environments — only an `app_env` variable differs, proving the app and pipeline are environment-agnostic by design.

## Key Design Decisions

- **Single Terraform module, multiple environments**: avoids duplicating infrastructure code — dev/prod/jenkins are just different inputs to the same module.
- **Manual approval before Prod**: production deployments are never fully automatic — this promotion gate reflects how real teams prevent unreviewed changes from reaching customers.
- **Secrets never touch the repository**: AWS credentials and SSH keys are stored in Jenkins' encrypted credential store, referenced by ID in the pipeline — never hardcoded.
- **Idempotent Ansible playbooks**: running the playbook multiple times produces the same end state, rather than accumulating changes.

## Rollback Strategy

If a deployment fails or introduces a bug in production:
1. Identify the last known-good image tag in ECR (each build is tagged with its Jenkins build number, e.g. `multi-env-app:7`).
2. Re-run the Ansible playbook manually with `--extra-vars "image_tag=<last-good-build-number>"` to redeploy the previous image, or trigger a new Jenkins build from an earlier Git commit.
3. Because Dev is deployed and verified *before* the approval gate, most issues are caught before they ever reach Prod.

## Local Development Note

This project was built entirely using **GitHub Codespaces** (for code editing, Git, and Ansible/Terraform execution) and **AWS CloudShell** (for AWS CLI access) — no local software installation was required, making it fully reproducible on any machine with just a browser.

## Repository Structure

.
├── app/ # Flask application + Dockerfile
├── terraform/
│ ├── modules/ec2-app/ # Reusable EC2 + security group + key pair module
│ └── environments/
│ ├── dev/
│ ├── prod/
│ └── jenkins/
├── ansible/
│ ├── inventories/ # Per-environment host definitions
│ ├── playbook.yml # App deployment playbook (Docker, ECR pull, run container)
│ └── jenkins-setup.yml # Jenkins server bootstrap playbook
└── Jenkinsfile # Pipeline definition (build → push → deploy → approve → deploy)