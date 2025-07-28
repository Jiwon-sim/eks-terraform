#!/bin/bash

echo "=== External DNS 배포 상태 확인 ==="
echo ""

echo "1. External DNS Pod 상태 확인:"
kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns -o wide

echo ""
echo "2. External DNS Service Account 확인:"
kubectl get sa external-dns -n kube-system -o yaml

echo ""
echo "3. External DNS 최근 로그 (마지막 50줄):"
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns --tail=50

echo ""
echo "4. External DNS Deployment 상태:"
kubectl get deployment -n kube-system -l app.kubernetes.io/name=external-dns

echo ""
echo "5. External DNS 설정 확인:"
kubectl describe deployment -n kube-system -l app.kubernetes.io/name=external-dns

echo ""
echo "6. Route53 권한 테스트 (Pod 내부에서 실행):"
echo "다음 명령어를 External DNS Pod에서 실행하여 권한을 확인하세요:"
echo "kubectl exec -n kube-system -it \$(kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns -o jsonpath='{.items[0].metadata.name}') -- aws route53 list-hosted-zones"

echo ""
echo "=== 문제 해결 가이드 ==="
echo "1. Pod가 Pending 상태인 경우: 노드 리소스 부족 또는 스케줄링 문제"
echo "2. Pod가 CrashLoopBackOff 상태인 경우: IAM 권한 또는 설정 문제"
echo "3. Pod가 Running이지만 DNS 레코드가 생성되지 않는 경우:"
echo "   - Route53 Hosted Zone ID 확인"
echo "   - 도메인 필터 설정 확인"
echo "   - Service/Ingress 어노테이션 확인"
echo ""
echo "External DNS 어노테이션 예시:"
echo "Service: external-dns.alpha.kubernetes.io/hostname: myapp.bluesunnywings.com"
echo "Ingress: kubernetes.io/ingress.class: alb"
echo ""
echo "=== 테스트 애플리케이션 배포 =="
echo "kubectl apply -f test-external-dns.yaml"
echo ""
echo "=== DNS 레코드 확인 =="
echo "nslookup nginx.bluesunnywings.com"
echo "nslookup app.bluesunnywings.com"