variable "region" {
  description = "AWS Region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used in resource names and tags."
  type        = string
  default     = "vpc-peering-lab"
}

variable "availability_zone" {
  description = "Single Availability Zone for ALL subnets (keeps cross-AZ data charges at zero). Leave empty to use the first available AZ in the Region."
  type        = string
  default     = ""
}

# ---- Addressing (must match config/network-plan.json) ----
variable "vpc_a_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_a_public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "vpc_a_private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "vpc_b_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "vpc_b_private_subnet_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

# ---- Access ----
variable "allowed_web_cidr" {
  description = "YOUR public IP in CIDR form, e.g. 203.0.113.25/32. Only this address may open the public instance's web page on port 8080. Find it by searching 'what is my IP'."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_web_cidr)) && var.allowed_web_cidr != "0.0.0.0/0"
    error_message = "Use a valid CIDR such as 203.0.113.25/32. 0.0.0.0/0 (the whole internet) is not allowed."
  }
}

variable "instance_type" {
  description = "EC2 instance type. Check your account's Free Tier / credits before choosing."
  type        = string
  default     = "t3.micro"
}
