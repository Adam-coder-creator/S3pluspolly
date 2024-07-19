variable "aws_s3_buckets"{
    description = "bucket name"
    default = ["amc-polly-destination-bucket-adam","amc-polly-source-bucket-adam"]
    type = list
      }