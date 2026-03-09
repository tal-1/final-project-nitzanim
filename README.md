<img width="923" height="622" alt="image" src="https://github.com/user-attachments/assets/3db3339c-dc0f-4f1b-87f9-3477bab45035" />



Github Actions Pipeline

1) GitHub runner setup - downloading the source code and installing the required python environment (Python 3.10).

***developer pushes code to feature branch - tagged with commit id***

2) code scanning (Linting - Flake8 + Bandit) - Flake8 catchs syntax errors. typos and style issues, Then Bandit scans out python code for security vulnerabilities (hardcoded passwords, SQL injection) before building the docker image.

3) Unit Testing (Pytest) - Runs our fast, isolated python unit tests (Verifies Django app logic).

4) Build & Container Scanning (Docker + Trivy) - builds the docker image (Django, Gunicorn and our code), tags the image with a unique Git Commit ID, Then Trivy scans it before pushing to AWS: ensures no vulnerable OS packages are introduced to the ECS cluster.

***pipeline deploys image to dev environment***

5) Secure AWS Authentication (OIDC) - instead of pushing the images to AWS using hard-coded access keys, we'll use OIDC which uses temporary signed tokens for pipeline runs.

6) Pushing to AWS - 1. The pipeline pushes the Trivy-approved docker image to ECR.
                    2. Rus python manage.py collectstatic to gather all CSS, JS and image files.
                    3. Pushes the static files to our Dev S3 Bucket, updates the ECS Fargate                           orchestrator and clears the CloudFront cache.

***dev merges code to main - tagged with SenVer (like v1.2.3). deploys image to stage environment***
System Integration Testing (SIT) - with Pytest
performance testing - with Locust

7) ECS Deployment & Cache Invalidation - The pipeline runs a temporary one-off ECS task that executes python manage.py migrate to safely update out PS. Update the Dev ECS task definition with the new Commit ID image tag. Finally, execute a CloudFront invalidation so users instantly see any CSS or image changes you made.

8) Stage Testing & Manual Production Release - The pipline deploys the v1.2.3 (semantic versioning) image like in step 7 but targets the Stage environment. Pytest fires automated tests against the live Stage URLs to make sure the application communicates properly with Redis and PS. Locust spins up virtual users and bombs the Stage environment to make sure the new code doesnt slow down the system under heavy load.

9) Manual Approval - The pipline stops, A lead engineer gets an alert to review the SIT and locust results and clicks "Approve" in github.

10) Production Release - Once approved the exact v1.2.3 image is deployed to Prod ECS, Prod DB is migrated and Prod CliudFront is invalidated.


environments for code testing

DEV environment - minimal resources, RDS on 1 AZ
STAGE & PROD - full scale environments with more computing resources, RDS on 2 AZs
