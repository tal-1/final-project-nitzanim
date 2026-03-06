<img width="923" height="622" alt="image" src="https://github.com/user-attachments/assets/3db3339c-dc0f-4f1b-87f9-3477bab45035" />



Github Actions Pipeline

1) GitHub runner setup - downloading the source code and installing the required python environment (Python 3.10).

***developer pushes code to feature branch - tagged with commit id***

2) code scanning (Linting - flake8) - static code scanning for syntax errors before building the docker image.

3) Build & Container Scanning (Docker + Trivy) - building the docker image and scanning it before pushing to AWS: ensures no vulnerable OS packages are introduced to the ECS cluster.

***pipeline deploys image to dev environment***

4) Secure AWS Authentication (OIDC) - instead of pushing the images to AWS using hard-coded access keys, we'll use OIDC which uses temporary signed tokens for pipeline runs.

5) Pushing to AWS - the pipeline pushes the image to ECR, the static files to S3, updates the ECS Fargate orchestrator and clears the CloudFront cache.

***dev merges code to main - tagged with SenVer (like v1.2.3). deploys image to stage environment***
System Integration Testing (SIT) - with Pytest
performance testing - with Locust

***manual approval***

6) ECS Deployment & Cache Invalidation - update the task definition with the new docker image tag, and deploy it to the Fargate cluster. Finally, execute a CloudFront invalidation so users instantly see any CSS or image changes you made.



environments for code testing

DEV environment - minimal resources, RDS on 1 AZ
STAGE & PROD - full scale environments with more computing resources, RDS on 2 AZs
