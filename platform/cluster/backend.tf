terraform {
  backend "s3" {
    bucket         = "s3-cloudfpc-state"
    key            = "cluster-marathon.terraform.tfstate"
    region         = "us-east-1"       
  }
}
