# S3 Bucket - Raw Video Uploads
resource "aws_s3_bucket" "video_raw" {
  bucket = "${var.project_name}-video-raw-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "${var.project_name}-video-raw"
    Project = var.project_name
  }
}

# S3 Bucket - Processed/Transcoded Videos (HLS output)
resource "aws_s3_bucket" "video_processed" {
  bucket = "${var.project_name}-video-processed-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "${var.project_name}-video-processed"
    Project = var.project_name
  }
}

# Random suffix for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Block public access on raw bucket
resource "aws_s3_bucket_public_access_block" "video_raw" {
  bucket = aws_s3_bucket.video_raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Processed bucket policy - allow CloudFront access
resource "aws_s3_bucket_policy" "video_processed" {
  bucket = aws_s3_bucket.video_processed.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.video_processed.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.video_cdn.arn
          }
        }
      }
    ]
  })
}

# Enable CORS on processed bucket (for HLS.js player)
resource "aws_s3_bucket_cors_configuration" "video_processed" {
  bucket = aws_s3_bucket.video_processed.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}

# S3 Event Notification - Trigger Lambda on video upload
resource "aws_s3_bucket_notification" "video_upload" {
  bucket = aws_s3_bucket.video_raw.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.video_transcode.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".mp4"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
