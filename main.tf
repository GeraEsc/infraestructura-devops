# --- Proveedor AWS ---
provider "aws" {
  region = "us-east-1"
}

# --- VPC ---
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.10.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-Jump-Linux-Web"
  }
}

# --- Subred pública ---
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "IGW"
  }
}

# --- Tabla de ruteo pública ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

# --- Asociación de tabla de rutas ---
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- Grupo de seguridad Jump Server ---
resource "aws_security_group" "sg_jump" {
  name        = "SG-Jump-SSH"
  description = "Permite acceso SSH desde Internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH desde cualquier IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Jump"
  }
}

# --- Grupo de seguridad Web Servers ---
resource "aws_security_group" "sg_web" {
  name        = "SG-Web-HTTP-SSH"
  description = "Permite HTTP desde Internet y SSH desde Jump Server"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP publico"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_jump.id]
    description     = "SSH desde Jump Server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Web"
  }
}

# --- Instancia Jump Server ---
resource "aws_instance" "jump_server" {
  ami                         = "ami-00a929b66ed6e0de6"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg_jump.id]
  associate_public_ip_address = true
  key_name                    = "vockey"

  tags = {
    Name = "Jump-Server"
  }
}

# --- 3 Instancias Web Linux ---
resource "aws_instance" "web_servers" {
  count                       = 3
  ami                         = "ami-00a929b66ed6e0de6"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg_web.id]
  associate_public_ip_address = true
  key_name                    = "vockey"

  tags = {
    Name = "Web-Server-${count.index + 1}"
  }
}

# --- Outputs ---
output "public_ip_jump_server" {
  value       = aws_instance.jump_server.public_ip
  description = "IP pública del Jump Server"
}

output "public_ips_web_servers" {
  value       = aws_instance.web_servers[*].public_ip
  description = "IPs públicas de los servidores web"
}
