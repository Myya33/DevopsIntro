#terraform state list shows all resources built
#terraform fmt
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.60.0"
    }
  }
  backend "s3" {
    bucket = "myya-bucket"
    key = "terraform.tfstate"
    region = "us-east-1"
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
#Define Default Security Group
resource "aws_default_security_group" "default" {
    vpc_id = aws_vpc.main.id

    ingress {
      protocol    = -1
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
#Public Subnets 10.0.0.0/24
resource "aws_subnet" "public" {
    count = var.public_subnet_count
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
resource "aws_subnet" "private" {
    count = var.private_subnet_count
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + var.public_subnet_count)
    tags = {
        "Name" = "${var.default_tags.env}-Private_Subnet-${data.aws_availability_zones.availability_zone.names[count.index]}"
    }
    availability_zone = data.aws_availability_zones.availability_zone.names[count.index]
    #8 = 8 added bit (10.0.0.0/16+8 --> 10.0.0.0/24)
    #count index = changes 3rd octect by adding 1 (10.0.0.0/24 --> 10.0.1.0/24)
}
#Public Route Table
resource "aws_route_table" "myya-public-route-table" {
    vpc_id = aws_vpc.main.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myya-igw.id
    }

  
  tags = {
    "Name" = "${var.default_tags.env}"
  }
  
}
#Private Route Table
resource "aws_route_table" "myya-private-route-table" {
    vpc_id = aws_vpc.main.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.myya-nat-gateway.id
    }

  
  tags = {
    "Name" = "${var.default_tags.env}"
  }
  
}
#Public route table associations
resource "aws_route_table_association" "public_subnet_assoc" {
    count = 2
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.myya-public-route-table.id
         
}
#Private route table associations
resource "aws_route_table_association" "private_subenet_assoc" {
    count = 2
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.myya-private-route-table.id
  
}



#IGW
resource "aws_internet_gateway" "myya-igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        "Name" = "${var.default_tags.env}"
    }
}

#EIP
resource "aws_eip" "nat-eip" {
    vpc = true
    
    tags = {
      "Name" = "myya-eip"
    }
}

#NAT
resource "aws_nat_gateway" "myya-nat-gateway" {
    subnet_id = aws_subnet.public.0.id
    allocation_id = aws_eip.nat-eip.id
    
    tags = {
      "Name" = "myya-ngw"
    }
    
}
