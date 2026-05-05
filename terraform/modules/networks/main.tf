resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name        = "eks-vpc-${var.environment}"
  }
}

resource "aws_subnet" "subnet-public-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block_1
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-public-1-${var.environment}"
  }
}

resource "aws_subnet" "subnet-public-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block_2
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-public-2-${var.environment}"
  }
}

resource "aws_subnet" "subnet-private-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block_1
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "eks-subnet-private-1-${var.environment}"
  }
}

resource "aws_subnet" "subnet-private-2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block_2
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "eks-subnet-private-2-${var.environment}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-igw-${var.environment}"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "eks-nat-eip-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}


resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet-public-1.id

  tags = {
    Name = "eks-nat-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "eks-public-rt-${var.environment}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "eks-private-rt-${var.environment}"
  }
}


resource "aws_route_table_association" "public-1" {
  subnet_id      = aws_subnet.subnet-public-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-2" {
  subnet_id      = aws_subnet.subnet-public-2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-1" {
  subnet_id      = aws_subnet.subnet-private-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-2" {
  subnet_id      = aws_subnet.subnet-private-2.id
  route_table_id = aws_route_table.private.id
}
