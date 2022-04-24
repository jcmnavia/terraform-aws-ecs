# Terraform template to deploy full stack ECS environment in AWS

## Elements deployed

- [ ] Aurora DB - <ins>MANUAL</ins>
- [ ] S3 Buckets - <ins>MANUAL</ins>
- [ ] ACM - Certificate - <ins>MANUAL</ins>
- [x] Security Group
- [x] VPC - Virtual Private Cloud
- [x] Subnets
- [x] ECR - Elastic Container Repository
- [x] ECS Cluster
- [x] CloudWatch log Group
- [x] ECS Task Definition - 2gb RAM, 1024 CPU
- [x] IAM Role
- [x] ALB - Application Load Balancer
- [x] ALB Target Group
- [x] ALB Listener - HTTP/HTTPS
- [x] ECS Service -

## How to execute

1. Create a `terraform.tfvars` file with your preferred configuration inside `/main` folder
2. Create a `.env.backend` file with your AWS credentials for storing the terraform state inside `/main` folder. This is useful for having the state in the cloud when working in teams.
3. Make sure you have created the manual resources
   1. **Terraform State:** Make sure you created an S3 bucket or a folder inside a bucket to only store the state of your terraform instances.
   2. **Task Definition Enviroments:** Make sure you created a S3 bucket with all your envs to make the cluster work. Remember to paste your bucket name and file to the task definition section.
   3. **Certificate Manager:** Make sure you have your HTTPS certificate created and pasted the ARN to the Load Balancer HTTPS section.
   4. **Aurora DB:** Create your DB instance manually if necessary.
4. Run the scripts
   ```bash
   terraform init -backend-config=.env.backend
   ```
   ```bash
   terraform plan
   ```
   ```bash
   terraform apply
   ```
