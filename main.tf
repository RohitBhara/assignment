provider "aws" {
  region = "eu-west-1"
  access_key ="AKIA53HMLGRZ4ES32XYB"
  secret_key = "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"
} 

resource "aws_s3_bucket" "A" { 
     bucket = "bucketfi"
}

resource "aws_s3_bucket_acl" "A" {
      bucket = aws_s3_bucket.A.id 
      acl = "private"
}
resource "aws_transfer_server" "sftp_server" {
  protocols               = [ "SFTP" ] 
} 

resource "aws_s3_bucket_versioning" "ver" {
  bucket = aws_s3_bucket.A.id
  versioning_configuration {
    status = "Enabled"
  } 
}

resource "aws_iam_policy" "s3_policy" {
  name        = "s3-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = ["s3:PutObject", "s3:GetObject"]
        Resource  = "${aws_s3_bucket.A.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "sftp_role" {
  name = "sftp-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  policy_arn = aws_iam_policy.s3_policy.arn
  role       = aws_iam_role.sftp_role.name
}
resource "aws_iam_policy" "sftp_policy" {
  name        = "sftp-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = ["sts:AssumeRole"]
        Resource  = aws_iam_role.sftp_role.arn
      }
    ]
  })
}

resource "aws_iam_user" "sftp_user" {
  name = "sftp-user"
}

resource "aws_iam_user_policy_attachment" "sftp_policy_attachment" {
  policy_arn = aws_iam_policy.sftp_policy.arn
  user       = aws_iam_user.sftp_user.name
}

resource "aws_s3_bucket_object" "csv_file" {
  bucket = aws_s3_bucket.A.id
  key    = "example.csv"
  source = "/path/to/example.csv"
}
resource "aws_s3_bucket_object" "excel_file" {
  bucket = aws_s3_bucket.A.id
  key    = "example.xlsx"
  source = "/path/to/example.xlsx"
}

resource "aws_s3_bucket_object" "json_file" {
  bucket = aws_s3_bucket.A.id
  key    = "example.json"
  source = "/path/to/example.json"
}
resource "aws_cloudwatch_event_rule" "check_data_rule" {
  name                = "check-data-rule"
  description         = "Checks for missing data from agencies"
  schedule_expression = "cron(0 12 * * ? *)"
}
resource "aws_s3_bucket_policy" "landing_bucket" {
  bucket = aws_s3_bucket.A.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DenyPublicAccess",
        Effect = "Deny",
        Principal = "*",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.A.arn,
          "${aws_s3_bucket.A.arn}/*"
        ],
        Condition = {
          StringNotEquals = {
            "aws:PrincipalOrgID": "EXAMPLEORGID"
          }
        }
      }
    ]
  })
} 
