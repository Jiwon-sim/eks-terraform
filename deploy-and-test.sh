#!/bin/bash

echo "=== EKS 클러스터 및 External DNS 배포 스크립트 ==="
echo ""

# Terraform 초기화 및 배포
echo "1. Terraform 초기화 중..."
terraform init

echo ""
echo "2. Terraform 계획 확인 중..."
terraform plan

echo ""
echo "배포를 계속하시겠습니까? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "3. Terraform 배포 중..."
    terraform apply -auto-approve
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=== 배포 완료! ==="
        echo ""
        
        # 중요한 출력 정보 표시
        echo "4. Route53 네임서버 정보 (도메인 등록업체에서 설정 필요):"
        terraform output route53_name_servers
        
        echo ""
        echo "5. Hosted Zone ID:"
        terraform output route53_zone_id
        
        echo ""
        echo "6. 도메인 설정 정보:"
        terraform output domain_configuration
        
        echo ""
        echo "=== 다음 단계 ==="
        echo "1. 위의 네임서버를 도메인 등록업체에서 설정하세요"
        echo "2. DNS 전파를 기다리세요 (최대 48시간)"
        echo "3. kubectl 설정: aws eks update-kubeconfig --region ap-northeast-1 --name \$(terraform output -raw cluster_name)"
        echo "4. External DNS 테스트: kubectl apply -f test-external-dns.yaml"
        echo "5. 상태 확인: ./check-external-dns.sh"
        
        echo ""
        echo "=== kubectl 설정 자동 실행 ==="
        CLUSTER_NAME=$(terraform output -raw cluster_name)
        aws eks update-kubeconfig --region ap-northeast-1 --name "$CLUSTER_NAME"
        
        echo ""
        echo "=== External DNS 상태 확인 ==="
        sleep 30  # External DNS 배포 대기
        ./check-external-dns.sh
        
    else
        echo "Terraform 배포 실패!"
        exit 1
    fi
else
    echo "배포가 취소되었습니다."
    exit 0
fi