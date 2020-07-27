provider "aws"{
    region = "ap-south-1"
    profile = "gyanvi999"

}




resource "aws_vpc" "MyVPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}





resource "aws_subnet" "Public-Subnet" {
  vpc_id     = "${aws_vpc.MyVPC.id}"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = true
   availability_zone = "ap-south-1a"


  tags = {
    Name = "Public-Subnet"
  }
}





resource "aws_subnet" "Private-Subnet" {
  vpc_id     = "${aws_vpc.MyVPC.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"


  tags = {
    Name = "Private-Subnet"
  }
}




resource "aws_internet_gateway" "Intrnet-Gateway" {
  vpc_id = "${aws_vpc.MyVPC.id}"

  tags = {
    Name = "Intrnet-Gateway"
    description = "Allow public subnet and VPC to connect to outside world or internet"
  }
}




resource "aws_route_table" "VPC-Router" {
  vpc_id = "${aws_vpc.MyVPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.Intrnet-Gateway.id}"
  }


  tags = {
    Name = "VPC-Router"
  }
}




resource "aws_route_table_association" "Association" {
  subnet_id      = aws_subnet.Public-Subnet.id
  route_table_id = aws_route_table.VPC-Router.id

}



resource "aws_security_group" "Wp-SG" {
  name        = "Wp-SG"
  description = "Allow TCP,ICMP-IPv4,HTTP,SSH to the wordpress EC2 instance"
  vpc_id      = aws_vpc.MyVPC.id

  ingress {
    description = "ALLOW SSH From VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ALLOW HTTP From VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ALLOW ICMP From VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ALLOW HTTPS From VPC"
    from_port   = 432
    to_port     = 432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
   Name =  "Wp-SG"

  }
}



resource "aws_security_group" "MYSQL-SG" {
  name        = "allow_tls"
  description = "Allow INBOUND traffic from wordpress to store data in Mysql"
  vpc_id      = aws_vpc.MyVPC.id

  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MYSQL-SG"
  }
}





resource "aws_instance" "Wordpress" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  key_name  = "mykey"
  availability_zone = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.Wp-SG.id]
  subnet_id = aws_subnet.Public-Subnet.id
  

  tags = {
    Name = "Wordpress"
  }
}



resource "aws_instance" "MYSQL" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name  = "mykey"

  vpc_security_group_ids = [aws_security_group.MYSQL-SG.id]
  subnet_id = aws_subnet.Private-Subnet.id
  

  tags = {
    Name = "MYSQL"
  }
}



resource "null_resource" "StartBrowsing" {
  provisioner "local-exec" {
  command = "start msedge ${aws_instance.Wordpress.public_ip}"
  }
}