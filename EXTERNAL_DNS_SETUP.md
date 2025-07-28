# External DNS 설정 가이드

## 개요
이 Terraform 코드는 AWS EKS 클러스터에 External DNS를 배포하여 Kubernetes Service와 Ingress 리소스에 대한 DNS 레코드를 자동으로 Route53에 생성합니다.

## 사전 요구사항

1. **Route53 Hosted Zone**: 관리할 도메인의 Hosted Zone이 Route53에 생성되어 있어야 합니다.
2. **도메인 소유권**: 실제 도메인을 소유하고 있어야 합니다.
3. **AWS 권한**: Route53 및 EKS 관련 권한이 있는 AWS 계정

## 설정 방법

### 1. 도메인 및 Hosted Zone 설정

이 Terraform 코드는 `bluesunnywings.com` 도메인에 대한 Route53 Hosted Zone을 자동으로 생성합니다.

```hcl
resource "aws_route53_zone" "main" {
  name = "bluesunnywings.com"
}

locals {
  hosted_zone_id = aws_route53_zone.main.zone_id  # 자동 생성된 Zone ID 사용
  domain_name    = "bluesunnywings.com"
}
```

### 2. 도메인 네임서버 설정

Terraform 배포 후 출력된 네임서버를 도메인 등록업체에서 설정해야 합니다:

```bash
# 배포 후 네임서버 확인
terraform output route53_name_servers
```

이 네임서버들을 도메인 등록업체(예: 가비아, 호스팅케이알 등)에서 DNS 설정에 입력하세요.

### 3. 배포

```bash
terraform init
terraform plan
terraform apply
```

### 4. 배포 확인

배포 후 다음 스크립트를 실행하여 External DNS 상태를 확인하세요:

```bash
chmod +x check-external-dns.sh
./check-external-dns.sh
```

## External DNS 사용 방법

### Service에 DNS 레코드 생성

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.bluesunnywings.com
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

### Ingress에 DNS 레코드 생성

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: myapp.bluesunnywings.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

## 현재 설정된 External DNS Arguments

```yaml
args:
- --source=service
- --source=ingress
- --domain-filter=bluesunnywings.com
- --provider=aws
- --policy=upsert-only
- --aws-zone-type=public
- --registry=txt
- --txt-owner-id=YOUR_HOSTED_ZONE_ID
- --log-level=info
- --interval=1m
```

## 문제 해결

### 1. Pod가 시작되지 않는 경우

```bash
kubectl describe pod -n kube-system -l app.kubernetes.io/name=external-dns
```

### 2. IAM 권한 문제

External DNS Pod에서 AWS API 호출이 실패하는 경우:

```bash
kubectl exec -n kube-system -it $(kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns -o jsonpath='{.items[0].metadata.name}') -- aws sts get-caller-identity
```

### 3. DNS 레코드가 생성되지 않는 경우

- Service/Ingress에 올바른 어노테이션이 있는지 확인
- 도메인 필터 설정이 올바른지 확인
- External DNS 로그에서 오류 메시지 확인

### 4. 로그 확인

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns -f
```

## 보안 고려사항

1. **최소 권한 원칙**: IAM 정책이 특정 Hosted Zone에만 접근하도록 제한됨
2. **TXT 레코드 소유권**: txt-owner-id를 통해 레코드 소유권 관리
3. **upsert-only 정책**: 기존 레코드 삭제 방지

## 참고 자료

- [External DNS 공식 문서](https://github.com/kubernetes-sigs/external-dns)
- [AWS Load Balancer Controller 문서](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Route53 문서](https://docs.aws.amazon.com/route53/)