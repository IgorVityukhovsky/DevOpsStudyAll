provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "clickhouse_RHEL" {
    ami = "ami-05723c3b9cf4bf4ff"
    instance_type = "t2.micro"
    vpc_security_group_ids =  [aws_security_group.allow_all.id]
    key_name =     "Admin"
}

resource "aws_instance" "vector_RHEL" {
    ami = "ami-05723c3b9cf4bf4ff"
    instance_type = "t2.micro"
    vpc_security_group_ids =  [aws_security_group.allow_all.id] 
    key_name =     "Admin" 
}

resource "aws_instance" "lighthouse_UBUNTU" {
    ami = "ami-08c40ec9ead489470"
    instance_type = "t2.micro"
    vpc_security_group_ids =  [aws_security_group.allow_all.id]
    key_name =     "Admin"
}


resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all trafic"
  

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
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
    Name = "allow_all"
  }
}
