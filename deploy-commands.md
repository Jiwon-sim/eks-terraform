# 배포 및 확인 명령어

## 1. Terraform 배포

```bash
# 초기화
terraform init

# 계획 확인
terraform plan

# 배포
terraform apply

# 출력 값 확인
terraform output
```

## 2. 중요한 출력 값들

배포 완료 후 다음 값들을 확인하세요:

- `route53_name_servers`: 도메인 네임서버 설정에 사용
- `acm_certificate_arn`: Ingress 설정에 사용
- `route53_zone_id`: DNS 레코드 확인에 사용

## 3. 도메인 네임서버 설정

Route53 네임서버를 도메인 등록업체에 설정:

```bash
# 네임서버 확인
terraform output route53_name_servers
```

## 4. 테스트 애플리케이션 배포

```bash
# kubectl 설정
aws eks --region ap-northeast-1 update-kubeconfig --name devsecops-eks

# ACM 인증서 ARN을 test-app.yaml에 추가 후 배포
kubectl apply -f test-app.yaml

# Ingress 상태 확인
kubectl get ingress test-app-ingress -o wide

# External DNS 로그 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns -f
```

## 5. 상태 확인 명령어

```bash
# Route53 레코드 확인
aws route53 list-resource-record-sets --hosted-zone-id $(terraform output -raw route53_zone_id)

# ACM 인증서 상태 확인
aws acm describe-certificate --certificate-arn $(terraform output -raw acm_certificate_arn)

# External DNS 파드 상태
kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns

# ALB 상태 확인
aws elbv2 describe-load-balancers --region ap-northeast-1
```

## 6. 접속 테스트

```bash
# DNS 전파 확인
dig app.bluesuunywings.com
nslookup app.bluesuunywings.com

# HTTPS 접속 테스트
curl -I https://app.bluesuunywings.com
```