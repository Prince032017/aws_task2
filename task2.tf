provider "aws" {
  region   = "ap-south-1"
  profile = "prince"
  access_key = "AKIAUE7CFK27QSB7VKOY"
  secret_key = "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"
}
resource "tls_private_key" "mykey" {
    algorithm = "RSA"
}


resource "local_file" "key" {
    content         =   tls_private_key.mykey.private_key_pem
    filename        =   "mykey.pem"
}


resource "aws_key_pair" "my_key" {
    key_name   = "mykey_new"
    public_key = tls_private_key.mykey.public_key_openssh
}
resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  instance_tenancy = "default"



  tags = {
    Name = "myfirstVPC"
}
  }
resource "aws_subnet" "mysubnet" {
  depends_on = [aws_vpc.vpc
 ]
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1b"
      tags = {
    Name = "myfirstsubnet"
  
}
}


resource "aws_internet_gateway" "igw" {
   depends_on = [aws_vpc.vpc
 ]
  vpc_id = "${aws_vpc.vpc.id}"



  tags = {
    Name = "mygw"
  }
  
}
resource "aws_route_table" "tf_route" {
 depends_on = [
  aws_vpc.vpc
 ]
 vpc_id = aws_vpc.vpc.id
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
 tags = {
  Name = "task2-tf-route"
 }
}
resource "aws_route_table_association" "tf_assoc" {
 depends_on = [
  aws_subnet.mysubnet
 ]

 subnet_id   = aws_subnet.mysubnet.id
 route_table_id = aws_route_table.tf_route.id
}
resource "aws_security_group" "tf_efs_sg" {
  name        = "tf_efs_sg"
  description = "NFS "
  vpc_id      = "${aws_vpc.vpc.id}"


  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


   ingress {
    description = "NFS"
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
ingress {
     description = "SSH from VPC"
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "my-tsk-sg"
  }
}
resource "aws_efs_file_system" "tf_efs" {
 creation_token = "tf-EFS-task2"
 tags = {
  Name = "awsEFS"
  }
}
resource "aws_efs_mount_target" "tf_mount" {
 depends_on = [
  aws_efs_file_system.tf_efs,
  aws_subnet.mysubnet,aws_security_group.tf_efs_sg
 ]
file_system_id = aws_efs_file_system.tf_efs.id
 subnet_id   = aws_subnet.mysubnet.id
 security_groups = [aws_security_group.tf_efs_sg.id]
}
resource "aws_efs_access_point" "efs_access" {
 depends_on = [
  aws_efs_file_system.tf_efs,
 ]
file_system_id = aws_efs_file_system.tf_efs.id
}
resource "aws_instance" "tf_webserver" {
depends_on = [
  aws_vpc.vpc,
  aws_subnet.mysubnet,aws_efs_file_system.tf_efs,
 ]
 count = 2
 ami      = "ami-08706cb5f68222d09"
 instance_type = "t2.micro"
  subnet_id   = aws_subnet.mysubnet.id
 security_groups = [ aws_security_group.tf_efs_sg.id ]
 key_name = "mykey_new"
connection {
  type   = "ssh"
  user   = "ec2-user"
  private_key = file("mykey_new.pem")
  host   = self.public_ip
    }

user_data = <<-EOF
      #! /bin/bash
      
       sudo yum install httpd -y
       sudo systemctl start httpd 
       sudo systemctl enable httpd
       sudo rm -rf /var/www/html/*
       sudo yum install -y amazon-efs-utils
       sudo apt-get -y install amazon-efs-utils
       sudo yum install -y nfs-utils
       sudo apt-get -y install nfs-common
       sudo file_system_id_1="${aws_efs_file_system.tf_efs.id}
       sudo efs_mount_point_1="/var/www/html"
       sudo mkdir -p "$efs_mount_point_1"
       sudo test -f "/sbin/mount.efs" && echo "$file_system_id_1:/ $efs_mount_point_1 efs tls,_netdev" >> /etc/fstab || echo "$file_system_id_1.efs.ap-south-1.amazonaws.com:/$efs_mount_point_1 nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
       sudo test -f "/sbin/mount.efs" && echo -e "\n[client-info]\nsource=liw"   >> /etc/amazon/efs/efs-utils.conf
       sudo mount -a -t efs,nfs4 defaults
       cd /var/www/html
       sudo yum insatll git -y
       sudo mkfs.ext4 /dev/xvdf1
       sudo rm -rf /var/www/html/*
       sudo yum install git -y 
    sudo git clone https://github.com/Prince032017/aws_task2,
        EOF


tags = {
Name = "myOS"
}
}
resource "aws_s3_bucket" "tf_s3bucket" {
  bucket = "098webbucket1"
  acl  = "public-read"

  tags = {
  Name = "098webbucket1"
  }
 }
 
 resource "aws_s3_bucket_object" "tf_s3_image-upload" {
depends_on = [
   aws_s3_bucket.tf_s3bucket,
  ]
   bucket = "098webbucket1"
   key   = "prince.png"
   source = "prince.png"
   acl   = "public-read"
 } 

locals {
  s3_origin_id = "${aws_s3_bucket.tf_s3bucket.id}"
 }
resource "aws_cloudfront_distribution" "tf_s3_distribution" {
  depends_on = [
   aws_s3_bucket_object.tf_s3_image-upload,
  ] 
  origin {
   domain_name ="${aws_s3_bucket.tf_s3bucket.bucket_regional_domain_name}"
   origin_id  = "${local.s3_origin_id}"
  }
 enabled       = true
 default_cache_behavior {
  allowed_methods = ["DELETE", "GET","HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods  = ["GET", "HEAD"]
  target_origin_id = "${local.s3_origin_id}"

  forwarded_values {
   query_string = false
 cookies {
    forward = "none"
   }
  }

  viewer_protocol_policy = "allow-all"
  min_ttl        = 0
  default_ttl      = 3600
  max_ttl        = 86400
 }  

 restrictions {
  geo_restriction {
   restriction_type = "none"
  }
 }
  
 viewer_certificate {
  cloudfront_default_certificate = true
 }
 }
resource "null_resource" "cluster" {
  depends_on = [
   aws_cloudfront_distribution.tf_s3_distribution,  
  ]
count = 2
  connection {
  type   = "ssh"
  user   = "ec2-user"
  private_key = tls_private_key.mykey.private_key_pem
  host   = aws_instance.tf_webserver[count.index].public_ip
}
  provisioner "remote-exec" {
   inline = [
     "sudo su <<EOF",
     "sudo echo \"<img src='http://${aws_cloudfront_distribution.tf_s3_distribution.domain_name}/${aws_s3_bucket_object.tf_s3_image-upload.key}'height='200' width='200' >\" >> /var/www/html/index.html",
     "EOF",
   ]
  }
 }
