# ACM 인증서 검증 문제 해결 가이드

## 🚨 현재 상황
- ACM 인증서가 `PENDING_VALIDATION` 상태에서 멈춤
- DNS 검증이 완료되지 않아 타임아웃 발생

## 🔧 해결 단계

### 1. 도메인 네임서버 설정 확인

현재 Route53 네임서버:
```
ns-1263.awsdns-29.org
ns-2034.awsdns-62.co.uk
ns-466.awsdns-58.com
ns-858.awsdns-43.net
```

**중요**: `bluesuunywings.com` 도메인의 네임서버를 위 Route53 네임서버로 설정해야 합니다.

### 2. 임시 해결책 - 인증서 검증 건너뛰기

현재 상황에서는 인증서 검증을 일시적으로 건너뛰고 나머지 인프라를 먼저 구성할 수 있습니다:

```bash
# 현재 실패한 리소스 제거
terraform destroy -target=aws_acm_certificate_validation.main

# 인증서만 생성 (검증 없이)
terraform apply -target=aws_acm_certificate.main
terraform apply -target=aws_route53_record.cert_validation
```

### 3. 수동 DNS 검증 확인

```bash
# DNS 검증 레코드 확인
aws route53 list-resource-record-sets --hosted-zone-id $(terraform output -raw route53_zone_id) | grep _acme-challenge

# DNS 전파 확인
dig _acme-challenge.bluesuunywings.com TXT
dig _acme-challenge.bluesuunywings.com TXT @8.8.8.8
```

### 4. 네임서버 설정 후 재시도

도메인 네임서버를 Route53으로 설정한 후:

```bash
# DNS 전파 대기 (최대 48시간)
dig NS bluesuunywings.com

# 전파 완료 후 인증서 검증 재시도
terraform apply -target=aws_acm_certificate_validation.main
```

## 🎯 권장 해결책

### Option 1: 네임서버 설정 후 재배포
1. 도메인 등록업체에서 네임서버를 Route53으로 변경
2. DNS 전파 대기 (2-48시간)
3. `terraform apply` 재실행

### Option 2: 검증 없이 진행
1. 인증서 검증 리소스 제거
2. 나머지 인프라 구성 완료
3. 나중에 수동으로 인증서 검증

## 🔄 현재 상태에서 계속 진행하기

```bash
# 실패한 검증 리소스 제거
terraform state rm aws_acm_certificate_validation.main

# 나머지 리소스 배포
terraform apply
```

이후 도메인 네임서버 설정이 완료되면 수동으로 인증서 검증을 완료할 수 있습니다.