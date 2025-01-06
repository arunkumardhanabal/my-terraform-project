resource "aws_vpc" "tf_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "pub_sub1" {
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = var.sub1_cidr
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pub_sub2" {
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = var.sub2_cidr
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.tf_vpc.id
}

resource "aws_route_table" "myRT" {
  vpc_id = aws_vpc.tf_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }
}

resource "aws_route_table_association" "RTa1" {
  route_table_id = aws_route_table.myRT.id
  subnet_id = aws_subnet.pub_sub1.id
}

resource "aws_route_table_association" "RTa2" {
  route_table_id = aws_route_table.myRT.id
  subnet_id = aws_subnet.pub_sub2.id
}

resource "aws_security_group" "mySG" {
  vpc_id = aws_vpc.tf_vpc.id

  ingress {
    description = "HTTP"
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "myS3" {
  bucket = "mys3on6jan2025"
}

resource "aws_instance" "test1" {
  ami = "ami-03fa85deedfcac80b"
  instance_type = "t2.micro"
  key_name = "SG-Anitha-KP"
  vpc_security_group_ids = [aws_security_group.mySG.id]
  subnet_id = aws_subnet.pub_sub1.id
  user_data = base64encode(file("userdata1.sh"))
}

resource "aws_instance" "test2" {
  ami = "ami-03fa85deedfcac80b"
  instance_type = "t2.micro"
  key_name = "SG-Anitha-KP"
  vpc_security_group_ids = [aws_security_group.mySG.id]
  subnet_id = aws_subnet.pub_sub2.id
  user_data = base64encode(file("userdata2.sh"))
}

resource "aws_lb" "myALB" {
  name = "test-ALB"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.mySG.id]
  subnets = [aws_subnet.pub_sub1.id, aws_subnet.pub_sub2.id]
}

resource "aws_lb_target_group" "myTG" {
  name = "test-TG"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.tf_vpc.id
}

resource "aws_lb_target_group_attachment" "myTGattach1" {
  target_group_arn = aws_lb_target_group.myTG.arn
  target_id        = aws_instance.test1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "myTGattach2" {
  target_group_arn = aws_lb_target_group.myTG.arn
  target_id = aws_instance.test2.id
  port = 80
}

resource "aws_lb_listener" "TGlistener" {
  load_balancer_arn = aws_lb.myALB.arn
  port = 80
  protocol = "HTTP"
  
    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.myTG.arn
    }
}

output "lbDNS" {
  value = aws_lb.myALB.dns_name
}
