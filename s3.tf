resource "aws_s3_bucket" "bucketv2" {
    bucket = "myya-bucketv2"

    tags = {
        #Name = "${var.default_tags.env}-bucketv2"
    }
  
}

resource "aws_s3_bucket_acl" "bucketv2" {
    bucket = aws_s3_bucket.bucketv2.id
    acl = "private"
}

#s3 resouce bucket policy 
data "aws_iam_policy_document" "bucketv2" {
    statement {
        sid = "public view"
        principals {
            type = "AWS"
            identifiers = [ "*" ]
        }
        actions = [
            "s3:*"
            ]
        resources = [
            "${aws_s3_bucket.bucketv2.arn}/*"
        ]
    }

}

#attach a policy
resource "aws_s3_bucket_policy" "bucketv2" {
    bucket = aws_s3_bucket.bucketv2.id
    policy = data.aws_iam_policy_document.bucketv2.json
  
}  