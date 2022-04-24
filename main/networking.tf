########################## NETWORKING VPC/SUBNETS CONFIGURATION ##################################

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.default_vpc.id
  tags = {
    Name        = "${var.project}-igw"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name        = "${var.project}-routing-table-public"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "pub_subnet" {
  vpc_id                  = aws_vpc.default_vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.project}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.default_vpc.id
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name        = "${var.project}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "route_table_association" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.pub_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.default_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-service-sg"
    Environment = "${var.environment}"
  }
}
