# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "bluesuunywings.com"
  
  tags = {
    Name = "bluesuunywings-zone"
  }
}

# ACM 인증서 생성
resource "aws_acm_certificate" "main" {
  domain_name               = "bluesuunywings.com"
  subject_alternative_names = ["*.bluesuunywings.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "bluesuunywings-cert"
  }
}

# DNS 검증 레코드 생성
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# 인증서 검증 완료 대기 (도메인 네임서버 설정 후 활성화)
# resource "aws_acm_certificate_validation" "main" {
#   certificate_arn         = aws_acm_certificate.main.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

#   timeouts {
#     create = "10m"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }