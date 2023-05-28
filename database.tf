resource "aws_db_subnet_group" "this" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.db1.id, aws_subnet.db2.id]

  tags = {
    Name = "rds_subnet_group"
  }
}

resource "aws_db_instance" "this" {
  identifier = "web-db"

  allocated_storage       = 20 #var.allocated_storage
  maintenance_window      = "Sat:00:00-Sat:03:00" #var.maintenance_window
  db_subnet_group_name    = aws_db_subnet_group.this.id
  engine                  = "mysql" #var.engine
  engine_version          = "5.7" #var.engine_version
  instance_class          = "db.t3.micro" #var.instance_class
  db_name                 = "apache2_db" #var.db_name
  username                = "apache2"  #var.username
  port                      = var.port
  #password                = var.password
  manage_master_user_password = true
  storage_encrypted       = true #var.storage_encrypted
  storage_type            = "gp2" #var.storage_type

  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]

  allow_major_version_upgrade = true #var.allow_major_version_upgrade
  auto_minor_version_upgrade  = true #var.auto_minor_version_upgrade
}