variable "deploy_profile" {
  description = "Specify the local AWS profile configuration to use."
}

variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default     = "us-east-1"
}

variable "consul_ami_id" {
  description = "The ID of the AMI to be used for the consul nodes."
  default     = "ami-a23feadf"
}