# **GitHub Actions Pipeline**

## **developer pushes code to feature branch - tagged with commit id**

### **Phase 1: Continuous Integration (CI) - "Build & Store"**

1) GitHub runner setup - Downloading the source code and installing the required Python environment (Python 3.10).

2) Code scanning (Linting - Flake8, SAST - Bandit) - Flake8 catches syntax errors, typos, and style issues. Bandit scans the Python code for security vulnerabilities (like hardcoded passwords or SQL injection).

3) IaC Security Scanning (Trivy) - Scans your Terraform .tf files for security misconfigurations (like leaving an S3 bucket public) before deploying.

4) `terraform init` & `terraform validate` - Initializes and validates all relevant Terraform working directories to check the code for basic syntax and structural errors.

5) Unit Testing (Pytest) - Runs fast and isolated Python unit tests.

6) Build & Container Scanning (Docker + Trivy) - The runner builds the Docker image using a Multi-Stage Build strategy.
To avoid public rate limits and speed up the download, the Dockerfile fetches its Python base image through our private ECR Pull Through Cache URI instead of reaching out to the public internet directly.

* Builder stage - First, a heavy "builder" stage installs compilers (like gcc) and builds the Python dependencies.
* Runner stage - Then, a lightweight "runner" stage simply copies the compiled artifacts and the Django application code, discarding the heavy build tools.
* This drastically reduces the final image size (lowering storage & data transfer costs). The pipeline tags this lean image with a unique Git Commit ID, then Trivy scans it to ensure no vulnerable OS packages are introduced to the ECS cluster.

7) Global ECR Secure AWS Authentication (OIDC) - Instead of pushing images to AWS using hard-coded long-term access keys, the pipeline uses OIDC (OpenID Connect) to request temporary, signed access tokens.

8) Pushes the Trivy-approved Docker image to ECR.

## **pipeline deploys image to dev environment**

### **Phase 2: Continuous Delivery (CD) - Dev Deployment**

9) Dev Secure AWS Authentication (OIDC) - requests temporary tokens to securely provision AWS infrastructure and execute deployment commands.

10) Infrastructure Sync - Runs `terraform init` and `terraform apply -auto-approve` for the Dev environment. (Purpose: Actually create or update the required AWS infrastructure so the "house" is built before the code moves in).

11) Dev Static Assets Sync - Runs `python manage.py collectstatic` via the Docker container using Django's Manifest storage and pushes these static files to the Dev S3 Bucket. (Purpose: Gather CSS/JS files and rename them with unique hashes, like `style.a1b2c3.css`, for zero-downtime cache updates).

12) Dev Database Migration & ECS Deployment - The pipeline runs a temporary one-off ECS task that executes `python manage.py migrate`. (Purpose: Safely update the Postgres schema FIRST, ensuring the new code doesn't crash from missing database columns).
Once successful, it updates the Dev ECS task definition with the new Commit ID image tag.
Invalidate CloudFront.

## **dev merges code to main - tagged with SemVer (like v1.2.3). deploys image to stage environment**

### **Phase 3: Continuous Delivery (CD) - Stage Verification**

13) Stage Secure AWS Authentication (OIDC) - requests temporary tokens to securely provision AWS infrastructure and execute deployment commands.

14) Image Promotion (Re-tagging) - Uses the AWS CLI to add the new `v1.2.3` SemVer tag to the existing Commit ID Docker image in ECR. (Purpose: Safely promote the exact image we tested in Dev without rebuilding it).

15) Stage Infrastructure Sync - Runs `terraform init` and `terraform apply -auto-approve` for Stage.

16) Stage Static Assets Sync - Runs `python manage.py collectstatic` via the Docker container using Django's Manifest storage and pushes these static files to the Stage S3 Bucket. (Purpose: Gather CSS/JS files and rename them with unique hashes for zero-downtime cache updates).

17) Stage Database Migration & ECS Deployment  - The pipeline runs a temporary one-off ECS task that executes `python manage.py migrate`. (Purpose: Safely update the Postgres schema FIRST, ensuring the new code doesn't crash from missing database columns).
Once successful, it updates the Stage ECS task definition with the new `v1.2.3` image tag.
Invalidate CloudFront.

18) System Integration & Performance Testing:

* SIT (Pytest): Fires automated tests against the live Stage URLs. (Purpose: Make sure the application communicates properly with Valkey and the RDS Postgres DB).
* Performance (Locust): Spins up virtual users and bombs the Stage environment.
* Automated Rollback: If the SIT or Locust tests fail, the pipeline uses AWS CLI to automatically revert the Stage ECS service to the previous "Known Good" task definition, and triggers a CloudFront invalidation to revert cached assets.

## **manual approval**

### **Phase 4: Production Release**

19) Prod Secure AWS Authentication (OIDC) - requests temporary tokens to securely provision AWS infrastructure and execute deployment commands.

20) Prod Infrastructure Plan - Runs `terraform init` & `terraform plan`, generates the production execution plan (`-out=tfplan`) and uploads it as a pipeline artifact without applying it yet.

21) Manual Approval - The pipeline stops using GitHub Environments. A lead engineer gets an alert to review the SIT/Locust results and the Prod Terraform Plan, then clicks "Approve". 

22) Production Release:

* Secure AWS Authentication (OIDC) (Runner re-auths after pause)
* Downloads the saved plan artifact, runs `terraform init`, and then runs `terraform apply tfplan` for Prod (which is protected by the Terraform `prevent_destroy` lifecycle block to prevent accidental deletion)
* Runs `python manage.py collectstatic` via the Docker container using Django's Manifest storage and pushes these static files to the Prod S3 Bucket
* Runs a temporary one-off ECS task that executes `python manage.py migrate` for the Prod DB
* Once successful, it updates the Prod ECS task definition with the exact `v1.2.3` image tag
* Invalidates the Prod CloudFront cache


environments for code testing

DEV environment - minimal resources, RDS on 1 AZ
STAGE & PROD - full scale environments with more computing resources, RDS on 2 AZs
