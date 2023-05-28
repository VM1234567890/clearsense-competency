data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.aws_ami_value]
  }
}

resource "aws_ebs_volume" "this" {
  availability_zone = "${var.region}a"
  size              = 20
}

resource "aws_s3_bucket" "example" {
  bucket = "git-bucket-clearsense"
  # Add other bucket configuration options as needed
}

resource "aws_s3_object" "home_html" {
  bucket = aws_s3_bucket.example.id
  key    = "home.html"
  source = "${path.module}/websource/index.html"
}

resource "aws_s3_object" "database_html" {
  bucket = aws_s3_bucket.example.id
  key    = "database.html"
  source = "${path.module}/websource/database.html"
}

resource "aws_s3_object" "server_js" {
  bucket = aws_s3_bucket.example.id
  key    = "server.js"
  source = "${path.module}/websource/server.js"
}

resource "aws_launch_template" "this" {
  name_prefix   = "web"
  image_id      = data.aws_ami.this.id
  instance_type = var.instance_type
  #vpc_security_group_ids = [aws_security_group.this.id]
  network_interfaces {
    subnet_id       = aws_subnet.this.id
    security_groups = [aws_security_group.this.id]
    #associate_public_ip_address = true
  }
  iam_instance_profile {
    name = aws_iam_role.custom_role.name
  }
  user_data = base64encode(<<-EOT
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd

# Install Node.js
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs

aws ec2 attach-volume --volume-id ${aws_ebs_volume.this.id} --instance-id $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --device /dev/xvdf

sleep 10  # Wait for the attachment to complete

sudo mkfs -t ext4 /dev/xvdf
sudo mkdir /mnt/ebs
sudo mount /dev/xvdf /mnt/ebs
echo "/dev/xvdf  /mnt/ebs  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
# Fetch the secret value and assign it to a variable
export SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "${aws_db_instance.this.master_user_secret[0].secret_arn}" --query 'SecretString' --output text)

# Extract the username and password using jq
USERNAME=$(echo $SECRET_VALUE | jq -r '.username')
PASSWORD=$(echo "$SECRET_VALUE" | jq -r '.password')

export DB_USER="$USERNAME"
export DB_PASSWORD="$PASSWORD"

export DB_HOST="${aws_db_instance.this.endpoint}"
export DB_NAME="${aws_db_instance.this.db_name}"

# Configure Apache to use the EBS volume as the default directory
sudo mv /var/www/html /var/www/html_backup  # Backup the original directory
sudo mkdir /mnt/ebs/html
sudo ln -s /mnt/ebs/html /var/www/html  # Create a symbolic link to the EBS volume

aws s3 cp s3://${aws_s3_bucket.example.id}/index.html /mnt/ebs/html/index.html
aws s3 cp s3://${aws_s3_bucket.example.id}/database.html /mnt/ebs/html/database.html

sudo mkdir /mnt/ebs/server
aws s3 cp s3://${aws_s3_bucket.example.id}/server.js /mnt/ebs/server/server.js
cd /mnt/ebs/server
# Install required dependencies
sudo yum install -y gcc-c++ make
npm init -y
npm install express

# Start the Node.js server
node server.js

sudo systemctl restart httpd
EOT
  )


  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "this" {
  availability_zones = ["${var.region}a"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  health_check_type = "ELB"
  load_balancers = [
    aws_elb.this.id
  ]
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "web_policy_up" {
  name                   = "web_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name          = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.web_policy_up.arn]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name                   = "web_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.web_policy_down.arn]
}

