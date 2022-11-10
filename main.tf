# provider section
variable "access_key" {}
variable "access_secret" {}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.access_secret
}


# VPC section
# We have main VPC with two subnets


variable "subnet_prefix_prod" {
  description = "cidr block for the prod subnet"
}

variable "subnet_prefix_dev" {
  description = "cidr block for the dev subnet"
}

resource "aws_vpc" "main-vpc" {
  cidr_block = "72.0.0.0/16"
  tags = {
    Name = "hangout-web"
  }
}

resource "aws_subnet" "subnet-0" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.subnet_prefix_prod
  availability_zone = "us-east-1a"

  tags = {
    Name = "hangout prod subnet"  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.subnet_prefix_dev
  availability_zone = "us-east-1a"

  tags = {
    Name = "hangout dev subnet"  }
}

# # Create Internet Gateway

resource "aws_internet_gateway" "gw" {
   vpc_id = aws_vpc.main-vpc.id


}



# # Create specific Route Table

resource "aws_route_table" "prod-route-table" {
   vpc_id = aws_vpc.main-vpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.gw.id
   }

   route {
     ipv6_cidr_block = "::/0"
     gateway_id      = aws_internet_gateway.gw.id
  }

   tags = {
     Name = "Prod"
   }
 }

# # 4. Create a Subnet 

# resource "aws_subnet" "subnet-1" {
#   vpc_id            = aws_vpc.prod-vpc.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-east-1a"

#   tags = {
#     Name = "prod-subnet"
#   }
# }

# # Associate subnet with Route Table
resource "aws_route_table_association" "a" {
   subnet_id      = aws_subnet.subnet-0.id
   route_table_id = aws_route_table.prod-route-table.id
 }


# # Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
   name        = "allow_web_traffic"
   description = "Allow Web inbound traffic"
   vpc_id      = aws_vpc.main-vpc.id

   ingress {
     description = "HTTPS"
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }

    ingress {
     description = "HTTP-Jen"
     from_port   = 8080
     to_port     = 8080
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }

   ingress {
     description = "SSH"
     from_port   = 22
     to_port     = 22
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
     Name = "allow_web"
   }
 }

# # 7. Create a network interface with an ip in the subnet that was created in step 4

# resource "aws_network_interface" "web-server-nic" {
#   subnet_id       = aws_subnet.subnet-1.id
#   private_ips     = ["10.0.1.50"]
#   security_groups = [aws_security_group.allow_web.id]

# }
# # 8. Assign an elastic IP to the network interface created in step 7

# resource "aws_eip" "one" {
#   vpc                       = true
#   network_interface         = aws_network_interface.web-server-nic.id
#   associate_with_private_ip = "10.0.1.50"
#   depends_on                = [aws_internet_gateway.gw]
# }

# output "server_public_ip" {
#   value = aws_eip.one.public_ip
# }

# # 9. Create Ubuntu server and install/enable apache2

variable "public_key" {}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = var.public_key
  }



resource "aws_instance" "ubuntu" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = aws_security_group.allow_web.id
  tags = {
    "Name" = "jenkins-m"
    "ENV"  = "Dev"
  }

# Type of connection to be established
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.public_key
    host        = self.public_ip
  }
depends_on = [aws_key_pair.deployer]

  # Remotely execute commands to install Java, Python, Jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo apt update && upgrade",
      "sudo apt install -y python3.8",
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ >  /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-8-jre",
      "sudo apt-get install -y jenkins",
    ]
  }


}
  

  




















resource "aws_instance" "jenkins-m" {
   ami               = "ami-08c40ec9ead489470"
   instance_type     = "t2.micro"
   availability_zone = "us-east-1a"
   key_name          = "main-key"
}
#   network_interface {
#     device_index         = 0
#     network_interface_id = aws_network_interface.web-server-nic.id
#   }

#   user_data = <<-EOF
#                 #!/bin/bash
#                 sudo apt update -y
#                 sudo apt install apache2 -y
#                 sudo systemctl start apache2
#                 sudo bash -c 'echo your very first web server > /var/www/html/index.html'
#                 EOF
#   tags = {
#     Name = "web-server"
#   }
# }



# output "server_private_ip" {
#   value = aws_instance.web-server-instance.private_ip

# }

# output "server_id" {
#   value = aws_instance.web-server-instance.id
# }


# resource "<provider>_<resource_type>" "name" {
#     config options.....
#     key = "value"
#     key2 = "another value"
# }
