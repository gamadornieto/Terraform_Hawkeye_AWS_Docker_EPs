
##################################################################################
# MAPPINGS
##################################################################################

variable "region_az" {
  type = "map"
  default = {
    us-east-1 = "us-east-1a"
    us-west-1 = "us-west-1a"
  }
}

variable "Docker-EP-AMI" {
  type = "map"
  default = {
    us-east-1 = "ami-08f3d892de259504d"
    us-west-1 = "ami-01311df3780ebd33e"
  }
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key =  var.aws_access_key_id
  secret_key =  var.aws_secret_access_key
  token      =  var.aws_session_token
  region     =  var.my_aws_region
}


##################################################################################
# VPC
##################################################################################

resource "aws_vpc" "main" {
  cidr_block       = "172.30.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "${var.environment_tag}-VPC"
    Options = var.options_tag
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.environment_tag}"
    Options = var.options_tag
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.30.0.0/24"
  availability_zone= var.region_az[var.my_aws_region]
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.environment_tag}-public_subnet1"
    Options = var.options_tag
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "aws_route_table" "public_rt" {
 vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.environment_tag}-public_rt"
    Options = var.options_tag
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "aws_route_table_association" "public_rt" {
	subnet_id = aws_subnet.public_subnet1.id
	route_table_id = aws_route_table.public_rt.id
}

##################################################################################
# EC2 EPs
##################################################################################

resource "aws_instance" "HawkeyeDockerEP" {

  count = var.num_docker-ep

  ami           =  var.Docker-EP-AMI[var.my_aws_region]
  instance_type =  "t2.nano"
  key_name        = var.key_name

  vpc_security_group_ids = ["${aws_security_group.gustavo-HawkeyeEP-sg.id}"]
  availability_zone= var.region_az[var.my_aws_region]
  subnet_id = aws_subnet.public_subnet1.id

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file(var.private_key_with_full_path )
    host     = self.public_ip
  }

  provisioner "remote-exec" {

    inline = [
      "sudo yum update -y",
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo systemctl enable docker",
      "wget https://${var.hawkeye_manager_ip}/download/install_xr_docker.sh --no-check-certificate",
      "sudo chmod +x install_xr_docker.sh",
      /*#
        # Fix error in EP script from HawkeManager Version 4.1.21 (10531310)
        # Need to use " to parse the $
      */
      "sudo cp install_xr_docker.sh install_xr_docker_orig.sh",
      "sudo sed -i s/probename=\\$2/probename=\\$1/ install_xr_docker.sh",
      "sudo sed -i s/server=\\$3/server=\\$1/ install_xr_docker.sh",
      "sudo sed -i 's/num_args -lt 2/num_args -lt 1/' install_xr_docker.sh",
      "sudo sed -i 's/num_args -lt 3/num_args -lt 2/' install_xr_docker.sh",
      "sudo ./install_xr_docker.sh DockerEP_${count.index} ${var.hawkeye_manager_ip}"
    ]
  }


  tags = {
    Name = "${var.environment_tag}-Docker-EP_${count.index}"
    Environment = var.environment_tag
    Type = "Docker-EP"
    Owner = var.owner_tag
  }
}


##
# SECURITY GROUPS #
##


# Learn my public IP address
data "http" "myip" {
   url = "http://icanhazip.com"
}


# HawkEye EP security group
resource "aws_security_group" "gustavo-HawkeyeEP-sg" {
  name        = "gustavo_HawEyeEP_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.environment_tag}-HawkeyeEP-sg"
    Options = var.options_tag
    Owner = var.owner_tag
    Environment = var.environment_tag
  }
}

##################################################################################
# OUTPUT
##################################################################################

output "HawkeyeDockerEP" {
    value = [for name in aws_instance.HawkeyeDockerEP[*].public_dns:  " ssh -i ${var.private_key_with_full_path} ec2-user@${name}" ]
}
