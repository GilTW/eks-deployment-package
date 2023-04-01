terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${aws.version}"
    }
  }

  backend "s3" {}
}


provider "aws" {
  region = "${aws.region}"
}
