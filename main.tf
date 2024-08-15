/// Data
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [ data.aws_vpc.default.id ]
  }
}

/// Creating SG
resource "aws_security_group" "instance" {
  name = "terraform-web-svr-sg"
      tags = {
        Name = "terraform-web-svr-sg"
      }
  ingress  {
    from_port = var.server-port
    to_port = var.server-port
       protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
///////


///// /// Creating ASG
resource "aws_autoscaling_group" "demo-asg" {
  launch_configuration = aws_launch_configuration.demo.name
  min_size = 2
  max_size = 3
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key = "Name"
    value = "makisam-demo-asg-instance"
    propagate_at_launch = true
    
  }
  vpc_zone_identifier = data.aws_subnets.default.ids
}

resource "aws_launch_configuration" "demo" {
  image_id = "ami-03a452ac694118fc7"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]
    user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt-get install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo Congratulations! on your first Webserver Installation > /var/www/html/index.html'
            EOF
}





///// Variable
variable "server-port" {
  description = "The port the server will use for HTTP requests"
  type = number
}

output "instance-public-ip" {
  value = "aws_launch_configuration.demo.associate_public_ip_address"
}
