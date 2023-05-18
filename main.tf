locals {
    tags = {
        terraform = true
        exercise = "Brillio"
    }
}
#Instruction 1
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = local.tags
}

#Instruction 2
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"
}

#Instruction 3
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  #No indication about gateway
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.lorem.id
  # }

  tags = local.tags
}

resource "aws_route_table_association" "table_subnet_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "table_subnet_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.route_table.id
}

#Instruction 4 and 5
data "aws_ami" "ubuntu_vm" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_launch_configuration" "launch_config" {
  name_prefix   = "launch_config"
  image_id      = data.aws_ami.ubuntu_vm.id
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "ag" {
  name                 = "ag"
  vpc_zone_identifier  = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  launch_configuration = aws_launch_configuration.launch_config.id
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2

  #Cool down
  default_cooldown = 120

  #Deregistration
  health_check_grace_period = 300

  #Warm up
  default_instance_warmup =  120
}
