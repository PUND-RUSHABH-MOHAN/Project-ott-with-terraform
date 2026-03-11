variable "region" {
  default = "ap-south-1" # <-- update if needed
}

# (Optional) If you want to interpolate the account_id
# data "aws_caller_identity" "current" {}

# Lambda Function - Video Transcode Trigger
resource "aws_lambda_function" "video_transcode" {
  filename         = "${path.module}/lambda/video-transcode.zip"
  function_name    = "${var.project_name}-video-transcode"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 256

  environment {
    variables = {
      OUTPUT_BUCKET       = aws_s3_bucket.video_processed.bucket
      MEDIACONVERT_ROLE   = "arn:aws:iam::442042523408:role/${var.project_name}-lambda-role"
      MEDIACONVERT_QUEUE  = "arn:aws:mediaconvert:${var.region}:442042523408:queues/Default"
    }
  }

  tags = {
    Project = var.project_name
  }
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.video_transcode.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.video_raw.arn
}

# Lambda Function - Video Status Callback
resource "aws_lambda_function" "video_status" {
  filename         = "${path.module}/lambda/video-status.zip"
  function_name    = "${var.project_name}-video-status"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      CLOUDFRONT_DOMAIN = aws_cloudfront_distribution.video_cdn.domain_name
    }
  }

  tags = {
    Project = var.project_name
  }
}

# CloudWatch Event Rule - MediaConvert Job Status Change
resource "aws_cloudwatch_event_rule" "mediaconvert_status" {
  name        = "${var.project_name}-mediaconvert-status"
  description = "Capture MediaConvert job state changes"

  event_pattern = jsonencode({
    source      = ["aws.mediaconvert"]
    detail_type = ["MediaConvert Job State Change"]
    detail = {
      status = ["COMPLETE", "ERROR"]
    }
  })
}

# CloudWatch Event Target - Trigger Lambda on MediaConvert completion
resource "aws_cloudwatch_event_target" "video_status" {
  rule      = aws_cloudwatch_event_rule.mediaconvert_status.name
  target_id = "VideoStatusLambda"
  arn       = aws_lambda_function.video_status.arn
}

# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.video_status.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mediaconvert_status.arn
}
