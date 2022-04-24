########################## VARS ##################################


variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile"
}


variable "project" {
  description = "Your project name"
  type        = string
}

variable "environment" {
  description = "Your app environment"
  type        = string
}

variable "task-bucket" {
  description = "Your bucket with the envs for the ECS task"
  type        = string
}

variable "acmarn" {
  description = "Your ACM certificate for the load balancer"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnets"
}

variable "private_subnets" {
  description = "List of private subnets"
}

variable "availability_zones" {
  description = "List of availability zones"
}
