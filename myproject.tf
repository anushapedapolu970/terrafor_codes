##MINI PROJECT :
  ##1. create a VPC  - 10.81.0.0/16
  #2. Create Internet Gateway 
  #3. Create Custom Route Table 
  #4. Create a Subnet  -- 10.81.3.0/24
  #5. Associate subnet with Route Table 
  #6. Create Security Group to allow port 22,80,443 or all ports , traffic  
  #7. Create a network interface with an ip in the subnet that was created in step 4  
  #8. Assign an elastic IP to the network interface created in step 7 
  #9. Create an ec2  server - LAUNCH APLICATION IN IT 
  provider "aws" {

    region = "us-east-1"
    
  }
##1. create a VPC  - 10.81.0.0/16

resource "aws_vpc" "prod-vpc" {

    cidr_block = "10.81.0.0/16"
    instance_tenancy = "default"

    tags = {
      Name = "prod_vpc"
    }
  
}
 #2. Create Internet Gateway 

resource "aws_internet_gateway" "prod_igw" {

    vpc_id = aws_vpc.prod-vpc.id

    tags = {

        Name = "Prod_igw"
    
    }

}
 #3. Create Custom Route Table 

 resource "aws_route_table" "prod_rt" {

    vpc_id = aws_vpc.prod-vpc.id

    route{

        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod_igw.id
    }

    tags = {
      Name = "prod_rt" 
    }
   
 }

 #4. Create a Subnet  -- 10.81.3.0/24

 resource "aws_subnet" "prod_subnet" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.81.3.0/24"

    tags = {

        Name = "prod_subnet"
 
    } 
 }
#5. Associate subnet with Route Table 

resource "aws_route_table_association" "publi_rta" {
subnet_id = aws_subnet.prod_subnet.id
route_table_id = aws_route_table.prod_rt.id  
}

 #6. Create Security Group to allow port 22,80,443 or all ports , traffic  

 resource "aws_security_group" "prod_sg" {

  name = "prod_sg"
  description = "to allow http https ssh"
  vpc_id = aws_vpc.prod-vpc.id

  ingress {

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  #usually ssh will ot allow from anywhere
  }

  ingress {

    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{

    from_port = 0
    to_port = 0
    protocol = "-1" #allow outbound traffic
    cidr_blocks =["0.0.0.0/0"]
  }
  tags = {

  Name = "prod_sg"
    
  }
 }

 #7. Create a network interface with an ip in the subnet that was created in step 4 

 resource "aws_network_interface" "prod_nic" {

  subnet_id = aws_subnet.prod_subnet.id
  description = "my nic"
  security_groups = [aws_security_group.prod_sg.id]
  private_ips = ["10.81.3.33"]

  tags = {
    
    Name = "prod_nic"
  }
 }

#8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "prod_eip" {

  domain = "vpc"
  network_interface = aws_network_interface.prod_nic.id
  associate_with_private_ip = "10.81.3.33" 

  tags = {
   Name = "prod_eip"
  }
  
}

resource "aws_instance" "prod_server" {
  ami                    = "ami-0de716d6197524dd9"
  instance_type          = "t2.micro"
  key_name               = "testkey"
  subnet_id              = aws_subnet.prod_subnet.id
  vpc_security_group_ids = [aws_security_group.prod_sg.id]
  private_ip             = "10.81.3.33"  # optional, static IP
  tags = {
    Name = "prod_server"
  }
}
output "prod_server_public_ip" {
  value = aws_instance.prod_server.public_ip
}
