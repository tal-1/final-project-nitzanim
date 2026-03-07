# Fetch the available Availability Zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    { Name = "${var.environment}-vpc" }
  )
}

# 2. Create the Internet Gateway (For Public Internet Access)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    { Name = "${var.environment}-igw" }
  )
}

# 3. Create 2 Public Subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # This math perfectly matches our earlier plan: .1 and .2
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  # Automatically hand out public IP addresses to things in this subnet
  map_public_ip_on_launch = true 

  tags = merge(
    var.tags,
    { Name = "${var.environment}-public-subnet-${count.index + 1}" }
  )
}

# 4. Create 2 Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # This math perfectly matches our earlier plan: .11 and .12
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 11)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    { Name = "${var.environment}-private-subnet-${count.index + 1}" }
  )
}

# 5. Create a NAT Gateway (Allows Private subnets to download updates/Docker images safely)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.environment}-nat-eip" })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  # We place the NAT Gateway in the first public subnet
  subnet_id     = aws_subnet.public[0].id 

  tags = merge(var.tags, { Name = "${var.environment}-nat" })
  depends_on = [aws_internet_gateway.main]
}

# 6. Route Tables (The "Traffic Cops")
# Public Route Table: Sends internet traffic to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, { Name = "${var.environment}-public-rt" })
}

# Private Route Table: Sends internet traffic to the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.tags, { Name = "${var.environment}-private-rt" })
}

# 7. Route Table Associations (Attaching the rules to the subnets)
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
