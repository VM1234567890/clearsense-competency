resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}


resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = "${var.region}a"

  tags = {
    Name = var.subnet_name
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.subnet_name}-public"
  }
}

resource "aws_subnet" "db1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_subnet1_cidr_block
  availability_zone = "${var.region}a"

  tags = {
    Name = "db_subnet1"            #var.db_subnet1_name
  }
}
resource "aws_subnet" "db2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_subnet2_cidr_block
  availability_zone = "${var.region}b"

  tags = {
    Name ="db_subnet2"            #var.db_subnet2_name
  }
}


resource "aws_security_group" "this" {
  name        = var.sg_name
  description = "${var.sg_description} (terraform-managed)"
  vpc_id    = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name = "web-rds-sg"

  description = "web-rds-sg (terraform-managed)"
  vpc_id      = aws_vpc.this.id

  # Only MySQL in
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block,]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.this.cidr_block,]
  }
}

# internet gateway and Nat

resource "aws_eip" "this"{
  #domain  = "vpc"
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "web_ig"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "web_nat"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "this" {
    vpc_id = aws_vpc.this.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.this.id
    }
    tags = {
        Name = "Public Subnets Route Table for My VPC"
    }
}

resource "aws_route_table_association" "this" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.this.id
}

resource "aws_route_table" "nat" {
    vpc_id = aws_vpc.this.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.this.id
    }
    tags = {
        Name = "private Subnet Route Table to NAT"
    }
}

resource "aws_route_table_association" "nat" {
    subnet_id = aws_subnet.this.id
    route_table_id = aws_route_table.nat.id
}


resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security Group"
  }
}
