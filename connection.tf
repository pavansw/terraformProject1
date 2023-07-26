terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.7.0"
    }
  }
}

provider "aws" {
	region = var.myregion
	access_key = var.myaccesskey
	secret_key = var.mysecretkey
}
