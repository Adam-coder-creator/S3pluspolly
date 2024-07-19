resource "aws_s3_bucket" "aws-all-s3bucket" {
  bucket = var.aws_s3_buckets[count.index]
  count = length(var.aws_s3_buckets)

  tags = {
    Name        =  "aws-my-buckets"
  
    Environment = "Dev"
  }
}

