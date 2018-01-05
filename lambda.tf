variable "headers" {
    default = {
        enabled = false
        hsts-enabled = false
        x-content-type-enabled = false
        x-frame-options-enabled = false
        x-xss-protection-enabled = false
    }
}

data "template_file" "function" {
  count = "${var.headers["enabled"] ? 1 : 0}"
  template = "${file("${path.module}/headers_function.js")}"

  vars {
    hsts = "${var.headers["hsts-enabled"]}"
    x-content-type = "${var.headers["x-content-type-enabled"]}"
    x-frame-options = "${var.headers["x-frame-options-enabled"]}"
    x-xss-protection = "${var.headers["x-xss-protection-enabled"]}"
  }
}

data "archive_file" "headers-function" {
  count = "${var.headers["enabled"] ? 1 : 0}"
  type = "zip"
  output_path = "${path.module}/.zip/headers_function.zip"
  source {
    filename = "index.js"
    content = "${data.template_file.function.rendered}"
  }
}

data "aws_iam_policy_document" "lambda-role-policy" {
  count = "${var.headers["enabled"] ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "headers-function" {
  count = "${var.headers["enabled"] ? 1 : 0}"
  name = "${var.alias}-lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-role-policy.json}"
}

resource "aws_iam_role_policy_attachment" "headers-function-role-policy" {
  count = "${var.headers["enabled"] ? 1 : 0}"
  role = "${aws_iam_role.headers-function.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "headers" {
  count = "${var.headers["enabled"] ? 1 : 0}"
  function_name = "${replace(var.alias, ".", "-")}-headers"
  filename = "${data.archive_file.headers-function.output_path}"
  source_code_hash = "${data.archive_file.headers-function.output_base64sha256}"
  role = "${aws_iam_role.headers-function.arn}"
  runtime = "nodejs6.10"
  handler = "index.handler"
  memory_size = 128
  timeout = 3
  publish = true
}
