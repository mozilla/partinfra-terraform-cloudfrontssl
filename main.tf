variable "origin_domain_name" {}
variable "origin_id" {}
variable "alias" {}
variable "acm_certificate_arn" {}
variable "origin_path" {
  default     = ""
}
variable "origin_http_port" {
  default     = 80
}
variable "origin_https_port" {
  default     = 443
}
variable "distribution_enabled" {
  default     = true
}
variable "comment" {
  default     = ""
}
variable "default_root_object" {
  default     = "index.html"
}
variable "compression" {
  default     = false
}

resource "aws_cloudfront_distribution" "ssl_distribution" {
  origin {
    domain_name = "${var.origin_domain_name}"
    origin_id   = "${var.origin_id}"
    origin_path = "${var.origin_path}"
    custom_origin_config {
      http_port = "${var.origin_http_port}"
      https_port = "${var.origin_https_port}"
      origin_protocol_policy = "https-only" # Only talk to the origin over HTTPS
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = "${var.distribution_enabled}"
  comment             = "${var.comment}"
  default_root_object = "${var.default_root_object}"

  aliases = ["${var.alias}"]
  price_class = "PriceClass_200"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.origin_id}"
    compress         = "${var.compression}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 360
    max_ttl                = 3600
  }


  cache_behavior {
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "${var.origin_id}"
      compress         = "${var.compression}"
      path_pattern     = "*"
      forwarded_values {
        query_string = false

        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 360
      max_ttl                = 3600

      lambda_function_association {
          event_type = "${var.headers["enabled"] ? "viewer-response" : ""}"
          // this currently does not work in Terraform
          //lambda_arn = "${var.headers["enabled"] ? aws_lambda_function.headers.arn : ""}"
          lambda_arn = "${aws_lambda_function.headers.arn}:${aws_lambda_function.headers.version}"

        }
  }

  restrictions {
    geo_restriction {
        restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.acm_certificate_arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}
