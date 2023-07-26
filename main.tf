### VPC Creation
resource "aws_vpc" "network1" {
	instance_tenancy = "default"
	cidr_block = "100.100.0.0/16"
	tags = {
		Name= "DevelopmentNetwork"
	}
}

### Internet Gateway
resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.network1.id

  tags = {
    Name = "Network1_Int_gateway"
  }
}

### Subnet on one AZ
resource "aws_subnet" "network1_sub1" {
  vpc_id = aws_vpc.network1.id
  cidr_block = "100.100.1.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "Network1_Subnet1"
  }
}

## Route Table
resource "aws_route_table" "myroute1" {
   vpc_id = aws_vpc.network1.id
   route {
       cidr_block = "0.0.0.0/0"
       gateway_id = aws_internet_gateway.mygw.id
       }
}

### Route table association with subnet
 resource "aws_route_table_association" "route_to_sub1" {
   subnet_id = aws_subnet.network1_sub1.id
   route_table_id = aws_route_table.myroute1.id
} 

## Security Group
resource "aws_security_group" "sg1" {
  name        = "allow_ssh_http"
  description = "Allow ssh and http inbound traffic "
  vpc_id      = aws_vpc.network1.id

  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http_ssh"
  }
}

## Instance as webserver on RHEL9
resource "aws_instance" "vm1" {
   ami = "ami-02acda7aaa1f944e5"
   instance_type = "t2.micro"
   associate_public_ip_address = true
   key_name = "testkey0"
   subnet_id = aws_subnet.network1_sub1.id
   vpc_security_group_ids = [aws_security_group.sg1.id]
   user_data = <<-EOF
   #!/bin/bash
   sudo dnf install httpd -y
   echo "Hello  from Pavan" > /var/www/html/index.html
   sudo systemctl start httpd
   EOF
   tags = {
      Name = "Webserver1"
	}
}

## 4gb Volume on EBS
resource "aws_ebs_volume" "vol1" {
  availability_zone = "ap-southeast-1a"
  size              = 4

  tags = {
    Name = "new Vol vol1"
  }
}

## attach volume to instance
 resource "aws_volume_attachment" "vol1attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.vol1.id
  instance_id = aws_instance.vm1.id
}



