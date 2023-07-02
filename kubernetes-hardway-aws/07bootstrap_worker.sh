for instance in worker-0 worker-1 worker-2; do
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo ssh -i kubernetes.id_rsa ubuntu@$external_ip

    scp -i kubernetes.id_rsa  autobootstrapworker.sh ubuntu@$external_ip:~/
    ssh -i kubernetes.id_rsa ubuntu@$external_ip sudo chmod +x autobootstrapworker.sh

    sleep 10
    ssh -i kubernetes.id_rsa ubuntu@$external_ip sudo ./autobootstrapworker.sh

    sleep 10
done



external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=controller-0" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

ssh -i kubernetes.id_rsa ubuntu@${external_ip} kubectl get nodes --kubeconfig admin.kubeconfig