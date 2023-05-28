#Account
variable "region" {
  type = string
}

# Network Variables
variable "vpc_cidr_block" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_cidr_block" {
  type = string
}

variable "public_subnet_cidr_block" {
  type = string
}

variable "db_subnet1_cidr_block" {
  type = string
}

variable "db_subnet2_cidr_block" {
  type = string
}


variable "subnet_name" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "sg_description" {
  type = string
}

# Compute Variables

variable aws_ami_value {
  type = string
}

variable instance_type {
  type = string
}

variable instance_name {
  type = string
}

variable key_name {
  type = string
}

#RDS Database

variable port{
    type = number
}