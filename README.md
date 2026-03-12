<img width="1047" height="581" alt="image" src="https://github.com/user-attachments/assets/cc1d12a8-7000-4123-96b2-7be4c0f7a951" />




Github Actions Pipeline

developer pushes code to feature branch - tagged with commit id

Phase 1: Validation (On Feature Branch)

1) GitHub runner setup - Downloading the source code and installing the required python environment (Python 3.10).

2)Code scanning (Linting - Flake8 + Bandit) - Flake8 catches syntax errors, typos, and style issues. Bandit scans the Python code for security vulnerabilities (like hardcoded passwords or SQL injection).

3) Unit Testing (Pytest) - Runs fast and isolated Python unit tests.

4) IaC Validation (Terraform Plan) - Runs `terraform plan` for the Dev environment, in order to verify that any new infrastructure configurations - like a new S3 bucket or environment variable - are syntactically correct and safe to apply.

5) Build & Container Scanning (Docker + Trivy) - Builds the Docker image (Django, Gunicorn, and code), tags the image with a unique Git Commit ID, then Trivy scans it.

pipeline deploys image to dev environment

Phase 2: Dev Deployment (Note: This phase strictly uses OIDC)

6) Secure AWS Authentication (OIDC) - Instead of pushing images to AWS using hard-coded long-term access keys, the pipeline uses OIDC (OpenID Connect) to request temporary, signed access tokens.

7) Infrastructure Sync - Runs `terraform apply` for the Dev environment. (Purpose: Actually create or update the required AWS infrastructure so the "house" is built before the code moves in).

8) Pushing to AWS:
a. Pushes the Trivy-approved Docker image to ECR.

b. Runs `python manage.py collectstatic` using Django's Manifest storage. (Purpose: Gather CSS/JS files and rename them with unique hashes, like `style.a1b2c3.css`, for zero-downtime cache updates).

c. Pushes these static files to our Dev S3 Bucket.

9) Database Migration & ECS Deployment - The pipeline runs a temporary one-off ECS task that executes `python manage.py migrate`. Once successful, it updates the Dev ECS task definition with the new Commit ID image tag. (Purpose: Safely update the Postgres schema FIRST, ensuring the new code doesn't crash from missing database columns).

dev merges code to main - tagged with SemVer (like v1.2.3). deploys image to stage environment

Phase 3: Stage Deployment & Verification

10) Stage Infrastructure Sync & Deployment - Runs `terraform apply` for Stage, runs the database migration, and deploys the `v1.2.3` image to the Stage ECS cluster exactly like step 9.

11) System Integration & Performance Testing:
a. SIT (Pytest): Fires automated tests against the live Stage URLs. (Purpose: Make sure the application communicates properly with Valkey and the RDS Postgres DB).

b. Performance (Locust): Spins up virtual users and bombs the Stage environment.

12) Automated Rollback - If the SIT or Locust tests fail, the pipeline automatically re-deploys the previous "Known Good" Docker image tag to the Stage ECS service.

manual approval

Phase 4: Production Release

13) Manual Approval - The pipeline stops. A lead engineer gets an alert to review the SIT and Locust results and clicks "Approve" in GitHub. 

14) Production Release - Once approved, the pipeline runs `terraform apply` for Prod (which is protected by the Terraform `prevent_destroy` lifecycle block to prevent accidental deletion), migrates the Prod DB, and finally deploys the exact `v1.2.3` image to the Prod ECS cluster. 


environments for code testing

DEV environment - minimal resources, RDS on 1 AZ
STAGE & PROD - full scale environments with more computing resources, RDS on 2 AZs
