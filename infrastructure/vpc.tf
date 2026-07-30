## XARXA ##

resource "aws_vpc" "vpc" {
  cidr_block            = var.vpc-cidr
  enable_dns_hostnames  = true
  enable_dns_support    = true
  tags                  = local.tags
}

resource "aws_subnet" "public" {
  count                 = length(var.aws-availability-zones)
  vpc_id                = aws_vpc.vpc.id
  availability_zone     = var.aws-availability-zones[count.index]
  cidr_block            = cidrsubnet(aws_vpc.vpc.cidr_block, 8, (count.index))
  tags                  = local.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id                = aws_vpc.vpc.id
  tags                  = local.tags
}

resource "aws_route_table" "public" {
  vpc_id                = aws_vpc.vpc.id
  route {
    cidr_block          = "0.0.0.0/0"
    gateway_id          = aws_internet_gateway.igw.id
  }
  tags                  = local.tags
}

resource "aws_route_table_association" "public" {
  count                 = length(aws_subnet.public)
  route_table_id        = aws_route_table.public.id
  subnet_id             = aws_subnet.public[count.index].id  
}

resource "aws_subnet" "private" {
  count                 = length(var.aws-availability-zones)
  vpc_id                = aws_vpc.vpc.id
  availability_zone     = var.aws-availability-zones[count.index]
  cidr_block            = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 2)
  tags                  = local.tags
}

resource "aws_route_table" "private" {
  vpc_id                = aws_vpc.vpc.id
  tags                  = local.tags
}

resource "aws_route_table_association" "private" {
  count                 = length(aws_subnet.private)
  subnet_id             = aws_subnet.private[count.index].id
  route_table_id        = aws_route_table.private.id
}





































