#terraform state list shows all resources built
#terraform fmt
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.60.0"
    }
  }
}

provider "aws" {
    region = "us-east-1" 
}

#create VPC; CIDR 10.0.0.0/16
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    assign_generated_ipv6_cidr_block = true
    enable_dns_hostnames = true 
    enable_dns_support = true
    #name vpc & tag vpc
    tags = {
      "Name" = "${var.default_tags.env}-VPC"
    }
}
#Public Subnets 10.0.0.0/24
resource "aws_subnet" "Public" {
    count = 2 
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
    tags = {
        "Name" = "${var.default_tags.env}-Public_Subnet-${data.aws_availability_zones.availability_zone.names[count.index]}"
    }
    availability_zone = data.aws_availability_zones.availability_zone.names[count.index]
    #8 = 8 added bit (10.0.0.0/16+8 --> 10.0.0.0/24)
    #count index = changes 3rd octect by adding 1 (10.0.0.0/24 --> 10.0.1.0/24)
    map_public_ip_on_launch = true
}
#Private Subnets 10.0.0.0/24
resource "aws_subnet" "Private" {
    count = 2 
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + var.public_subnet_count)
    tags = {
        "Name" = "${var.default_tags.env}-Private_Subnet-${data.aws_availability_zones.availability_zone.names[count.index]}"
    }
    availability_zone = data.aws_availability_zones.availability_zone.names[count.index]
    #8 = 8 added bit (10.0.0.0/16+8 --> 10.0.0.0/24)
    #count index = changes 3rd octect by adding 1 (10.0.0.0/24 --> 10.0.1.0/24)
}
#Route Tables 
#IGW
#NAT