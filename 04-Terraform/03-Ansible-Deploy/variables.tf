variable "key_name" {
  default = "aws"
}

variable "pvt_key" {
  default = "/var/lib/jenkins/.ssh/aws.pem"
}

variable "us-east-zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "sg-id" {
  default = "sg-00378f33e5e41eecb"
}
