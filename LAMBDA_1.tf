data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "amc-polly-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [aws_iam_policy.policy_one.arn, aws_iam_policy.policy_two.arn]
}
resource "aws_iam_policy" "policy_one" {
  name = "amc-polly-lambda-policy-adam"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:GetObject",
              "s3:PutObject"
          ],
          "Resource": [
              "arn:aws:s3:::amc-polly-source-bucket-adam/*",
              "arn:aws:s3:::amc-polly-destination-bucket-adam/*"
          ]
      },
      {
          "Effect": "Allow",
          "Action": [
              "polly:SynthesizeSpeech"
          ],
          "Resource": "*"
      }
  ]
}
  )
}
resource "aws_iam_policy" "policy_two" {
  name = "AWSLambdaBasicExecutionRole"

  policy = jsonencode({
    
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
      },
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "${path.module}/python/"
  output_path = "${path.module}/python/texttospeechfunction.zip"
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/python/texttospeechfunction.zip"
  function_name = "Texttospeechfunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "texttospeechfunction.lambda_handler"

  #source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.8"

  environment {
    variables = {
      SOURCE_BUCKET = "amc-polly-source-bucket-adam"
      DESTINATION_BUCKET = "amc-polly-destination-bucket-adam"
    }
  }
}
/*#trigger by s3 bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "amc-polly-destination-bucket-adam"

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    #filter_prefix       = "AWSLogs/"
    filter_suffix       = ".txt"
  }
}

data "aws_iam_policy_document" "queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:*:*:s3-event-notification-queue"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.bucket.arn]
    }
  }
}

resource "aws_sqs_queue" "queue" {
  name   = "s3-event-notification-queue"
  policy = data.aws_iam_policy_document.queue.json
}

resource "aws_s3_bucket" "bucket" {
  bucket = "amc-polly-destination-bucket-adam-1995"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.aws-all-s3bucket[0].id

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".txt"
  }
}
*/

resource "aws_lambda_permission" "allow_terraform_bucket" {
   statement_id = "AllowExecutionFromS3Bucket"
   action = "lambda:InvokeFunction"
   function_name = "${aws_lambda_function.test_lambda.arn}"
   principal = "s3.amazonaws.com"
   source_arn = "${aws_s3_bucket.aws-all-s3bucket[1].arn}"
}

resource "aws_s3_bucket_notification" "my-trigger" {
  bucket = "amc-polly-source-bucket-adam"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.test_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    #filter_prefix       = "file-prefix"
    filter_suffix       = ".txt"
  }
}