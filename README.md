# EKS Terraform Infrastructure

이 프로젝트는 AWS EKS 클러스터를 Terraform으로 구성하는 Infrastructure as Code입니다.

## 구성 요소

- **EKS 클러스터**: Kubernetes 1.28 버전
- **VPC**: 3개 AZ에 걸친 프라이빗/퍼블릭 서브넷
- **노드 그룹**: t3.micro 인스턴스로 구성된 관리형 노드 그룹
- **Add-ons**:
  - AWS Load Balancer Controller
  - AWS EBS CSI Driver
  - External DNS

## 사용법

1. AWS CLI 설정
```bash
aws configure
```

2. Terraform 초기화
```bash
terraform init
```

3. 계획 확인
```bash
terraform plan
```

4. 배포
```bash
terraform apply
```

## 정리

```bash
terraform destroy
```

## 주의사항

- 이 구성은 AWS 리소스를 생성하므로 비용이 발생할 수 있습니다
- 사용 후 반드시 `terraform destroy`로 리소스를 정리하세요