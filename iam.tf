resource "aws_iam_policy" "custom_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "${aws_db_instance.this.master_user_secret[0].secret_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "${aws_s3_bucket.example.arn}/*"
    }
  ]
}
EOF
}


resource "aws_iam_role" "custom_role" {
  name               = "CustomRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "custom_attachment" {
  role       = aws_iam_role.custom_role.name
  policy_arn = aws_iam_policy.custom_policy.arn
}

resource "aws_iam_instance_profile" "custome_profile" {
  name = "web-iam-instance-profile"
  role = aws_iam_role.custom_role.name
}

