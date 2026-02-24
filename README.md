<img width="1310" height="518" alt="image" src="https://github.com/user-attachments/assets/5db184e9-c018-4db0-b53c-68306404affe" />


TF file hierarchy:

terraform-status-page/
├── environments/               
│   ├── dev/                    
│   │   ├── backend.tf          <-- (tells terraform exactly where to save dev's state)
│   │   ├── main.tf             <-- (calling the modules for Dev)
│   │   ├── variables.tf        <-- (uses the variables)
│   │   └── terraform.tfvars    <-- (GITIGNORED: where variables & secrets are defined)
│   ├── stage/                  
│   │   ├── backend.tf          <-- (keeps stage state completely isolated)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/                   
│       ├── backend.tf          <-- (keeps prod state completely isolated)        
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars    
│
├── modules/                    
│   ├── networking/             <-- (VPC, Subnets, NAT Gateways, Route Tables)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf          <-- (Exports the vpc_id)
│   ├── security/               <-- (Security Groups for ALB, ECS, and DB)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf          <-- (Exports the security_group_ids)
│   ├── compute/                <-- (Merges ALB + ECS Fargate + Target Groups)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf          <-- (Exports the ALB DNS name)
│   ├── frontend/               <-- (Merges S3 + CloudFront + OAC)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf          <-- (Exports the CloudFront URL)
│   └── database/               <-- (RDS PostgreSQL + ElastiCache Valkey)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf          <-- (Exports database endpoints)
│
└── global/                     
    ├── ecr/                    
    │   ├── main.tf
    │   └── outputs.tf          <-- (Exports the repository URL for GitHub Actions)
    ├── github_oidc/            <-- (Secure CI/CD IAM Roles)
    │   ├── main.tf
    │   └── outputs.tf          <-- (Exports the Role ARN for the pipeline)
    └── s3-backend/             <-- (Creates the actual S3 bucket to hold the backend.tf states)
        ├── main.tf
        └── outputs.tf
