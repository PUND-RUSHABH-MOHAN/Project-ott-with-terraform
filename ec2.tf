# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance for WordPress
resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2 php php-mysql php-curl php-gd php-xml php-mbstring libapache2-mod-php mysql-server unzip

              # Start Apache
              sudo systemctl start apache2
              sudo systemctl enable apache2

              # Download WordPress
              cd /tmp
              wget https://wordpress.org/latest.tar.gz
              tar -xzf latest.tar.gz
              sudo cp -r wordpress/* /var/www/html/
              sudo chown -R www-data:www-data /var/www/html/
              sudo chmod -R 755 /var/www/html/

              # Configure MySQL
              sudo mysql -e "CREATE DATABASE ${var.db_name};"
              sudo mysql -e "CREATE USER '${var.db_user}'@'localhost' IDENTIFIED BY '${var.db_password}';"
              sudo mysql -e "GRANT ALL PRIVILEGES ON ${var.db_name}.* TO '${var.db_user}'@'localhost';"
              sudo mysql -e "FLUSH PRIVILEGES;"

              # WordPress config
              sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
              sudo sed -i "s/database_name_here/${var.db_name}/" /var/www/html/wp-config.php
              sudo sed -i "s/username_here/${var.db_user}/" /var/www/html/wp-config.php
              sudo sed -i "s/password_here/${var.db_password}/" /var/www/html/wp-config.php

              # Remove default index.html
              sudo rm -f /var/www/html/index.html

              # Restart Apache
              sudo systemctl restart apache2
              EOF

  tags = {
    Name    = "${var.project_name}-wordpress-ec2"
    Project = var.project_name
  }
}
