terraform {
  backend "local" {
    path = "/tmp/terraform/workspace/terraform.tfstate"
  }

}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_network" {
    cidr_block              = "10.10.0.0/16"
    enable_dns_hostnames    = true
    tags = {
        Name = "spring-petclinic"
    }
}

resource "aws_subnet" "pub_subnet" {
    cidr_block              = "10.10.0.0/24"
    vpc_id                  = "${aws_vpc.my_network.id}"
    availability_zone       = "us-east-1a"
    tags = {
        Name = "spring-petclinic"
    }

}

resource "aws_internet_gateway" "my_igw" {
    vpc_id      = "${aws_vpc.my_network.id}"
    tags = {
        Name = "spring-petclinic"
    }

}

resource "aws_route_table" "my_rt" {
    vpc_id = "${aws_vpc.my_network.id}"

    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = "${aws_internet_gateway.my_igw.id}"
    }

    tags = {
        Name = "spring-petclinic"
    }

}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.pub_subnet.id}"
  route_table_id = "${aws_route_table.my_rt.id}"
}

resource "aws_security_group" "my_sg" {
    name            = "my_sg"
    description     = "created from terraform"
    vpc_id          = "${aws_vpc.my_network.id}"
    ingress{
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "-1"
        from_port   = "0"
        to_port     = "0"
    }
    egress{
        cidr_blocks = ["0.0.0.0/0"]
        protocol    = "-1"
        from_port   = "0"
        to_port     = "0"
    }
    tags = {
        Name = "spring-petclinic"
    }
}


resource "aws_instance" "petclinic-web" {
    ami                         = "ami-0f2cc133ca38673a8"
    instance_type               = "t2.micro"
    key_name                    = "${var.key_name}"
    subnet_id                   = "${aws_subnet.pub_subnet.id}"
    associate_public_ip_address = true
    vpc_security_group_ids      = [ "${aws_security_group.my_sg.id}" ]
    tags = {
        Name = "spring-petclinic"
    }

}

resource "null_resource" "ansible-main" {
provisioner "local-exec" {
  command = <<EOT
        sleep 100;
        > jenkins-ci.ini;
        echo "[jenkins-ci]"| tee -a jenkins-ci.ini;
        export ANSIBLE_HOST_KEY_CHECKING=False;
        echo "${aws_instance.petclinic-web.public_ip}" | tee -a jenkins-ci.ini;
    EOT
}
}
