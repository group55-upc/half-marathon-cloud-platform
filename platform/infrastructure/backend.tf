terraform {
  backend "s3" {
    bucket         = "s3-cloudfpc-state"
    key            = "infrastructure.terraform.tfstate"
    region         = "us-east-1"       
  }
}
