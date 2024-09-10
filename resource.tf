resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
 
variable "prefix" {
  type    = string
  default = "EC2-DEP"
}
 
resource "aws_vpc" "main" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "${var.prefix}-vpc"
  }
}
 
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.0.0/24"
  tags = {
    Name = "${var.prefix}-subnet"
  }
}
 
variable "sg_rules" {
  description = "Security group rules"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = optional(string, "-1")
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}
 
resource "aws_security_group" "default" {
  name        = "my_first_sg"
  description = "testing security group"
  vpc_id      = aws_vpc.main.id
 
  dynamic "ingress" {
    for_each = [for rule in local.sg_rules : rule if rule.type == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
 
  dynamic "egress" {
    for_each = [for rule in local.sg_rules : rule if rule.type == "egress"]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
}
 
 
 
 
locals {
  sg_rules = [
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
    },
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "http"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "https"
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1" # Allow all protocols
      cidr_blocks = ["0.0.0.0/0"]
      description = "All traffic"
    }
  ]
}