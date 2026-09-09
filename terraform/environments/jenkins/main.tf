terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

module "jenkins_server" {
  source        = "../../modules/ec2-app"
  environment   = "jenkins"
  ami_id        = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.medium"
}

output "jenkins_public_ip" {
  value = module.jenkins_server.public_ip
}

output "private_key_pem" {
  value     = module.jenkins_server.private_key_pem
  sensitive = true
}