data "aws_ami" "ubuntu-linux-2004"{
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["ubuntu-eks/k8s_1.21/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    } 
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}
resource "aws_instance" "main"{
    ami = data.aws_ami.ubuntu-linux-2004.id
    instance_type = "t2.micro"
    key_name = "MyyaKey"
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [aws_default_security_group.default.id]
    
    tags = {
      "Name" = "${var.default_tags.env}-ec2"
    }


    user_data = base64encode(file("C:\\Users\\MyyaB\\OneDrive\\Desktop\\terraform\\user.sh"))
}
output "ec2_ssh_command" {
    value = "ssh -i MyyaKey.pem ubuntu@ec2-${replace(aws_instance.main.public_ip, ".", "-")}.compute-1.amazonaws.com"
}