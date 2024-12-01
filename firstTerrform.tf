terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}


#create VPC

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
 
  tags = { Name = "main-vpc" }
}

#create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id #VPC name
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  tags = { Name = "public-subnet" }
}

#create private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id  #VPC name
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"
  tags = { Name = "private-subnet" }
}



#create public add subnet
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id #VPC name
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-west-2a"
  tags = { Name = "public-subnet" }
}




#create internetgateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id          #Attach with VPC name
  tags = { Name = "main-igw" }
}

#Add internet gateway in route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-route-table" }
}


#Associate public Ip in route Table
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#create private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "private-route-table" }
}

#Associate private IP with Route table
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


#create ElasticIP
resource "aws_eip" "nat_eip" {
  vpc = true
}

#create NAT Gateway and associate with elastic IP and public IP
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  tags = { Name = "nat-gateway" }
}


#Assicate NAT gateway with private route table
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}


