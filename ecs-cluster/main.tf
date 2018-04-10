provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_network_acl" "mesh-vpc-network-acl" {
    vpc_id = "vpc-e8eb6f8f"
    subnet_ids = ["${aws_subnet.mesh-vpc-subnet1.id}", "${aws_subnet.mesh-vpc-subnet2.id}"]
    
    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    ingress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    tags {
        Name = "mesh-vpc-network-acl"
    }
}


resource "aws_route_table" "mesh-vpc-route-table" {
  vpc_id = "vpc-e8eb6f8f"

  route {
    cidr_block = "10.0.0.0/0"
    gateway_id = "igw-aab4c4ce"
  }

  tags {
    Name = "mesh-vpc-route-table"
  }
}

resource "aws_route_table_association" "mesh-vpc-route-table-association1" {
  subnet_id      = "${aws_subnet.mesh-vpc-subnet1.id}"
  route_table_id = "${aws_route_table.mesh-vpc-route-table.id}"
}

resource "aws_route_table_association" "mesh-vpc-route-table-association2" {
  subnet_id      = "${aws_subnet.mesh-vpc-subnet2.id}"
  route_table_id = "${aws_route_table.mesh-vpc-route-table.id}"
}


resource "aws_security_group" "mesh-vpc-security-group" {
    name        = "mesh-vpc-security-group"
    description = "Allow HTTP, HTTPS, and SSH"
    vpc_id = "vpc-e8eb6f8f"

    // HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // HTTPS
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "security-group-id" {
  value = "${aws_security_group.mesh-vpc-security-group.id}"
}


resource "aws_subnet" "mesh-vpc-subnet1" {
    vpc_id     = "vpc-e8eb6f8f"
    cidr_block = "10.0.7.0/24"
    availability_zone = "ap-southeast-2a"

    tags {
        Name = "mesh-vpc-subnet"
    }
}

resource "aws_subnet" "mesh-vpc-subnet2" {
    vpc_id     = "vpc-e8eb6f8f"
    cidr_block = "10.0.8.0/24"
    availability_zone = "ap-southeast-2b"

    tags {
        Name = "mesh-vpc-subnet"
    }
}

output "subnet1-id" {
  value = "${aws_subnet.mesh-vpc-subnet1.id}"
}

output "subnet2-id" {
  value = "${aws_subnet.mesh-vpc-subnet2.id}"
}

module "iam" {
    source = "./iam"
}



module "ec2" {
    source = "./ec2"

    vpc-id                      = "vpc-e8eb6f8f"
    security-group-id           = "${aws_security_group.mesh-vpc-security-group.id}"
    subnet-id-1                 = "${aws_subnet.mesh-vpc-subnet1.id}"
    subnet-id-2                 = "${aws_subnet.mesh-vpc-subnet2.id}"
    ecs-instance-role-name      = "${module.iam.ecs-instance-role-name}"
    ecs-instance-profile-name   = "${module.iam.ecs-instance-profile-name}"
    ecs-cluster-name            = "${var.ecs-cluster-name}"
    ecs-key-pair-name           = "${var.ecs-key-pair-name}"
}

module "ecs" {
    source = "./ecs"

    ecs-cluster-name            = "${var.ecs-cluster-name}"
    ecs-load-balancer-name      = "${module.ec2.ecs-load-balancer-name}"
    ecs-target-group-arn        = "${module.ec2.ecs-target-group-arn}"
    ecs-service-role-arn        = "${module.iam.ecs-service-role-arn}"
}
