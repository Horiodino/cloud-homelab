#  now send the autobootstrapetcd.sh to all the controlplanes  and then run these commands
#  send the autobootstrapetcd.sh to all the controlplanes  and then run these commands
# chmod +x bootstrap-etcd.sh then run it

for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa bootstrap-etcd.sh ubuntu@$external_ip:~/
  ssh -i kubernetes.id_rsa ubuntu@$external_ip sudo chmod +x bootstrap-etcd.sh  

  sleep 10
  ssh -i kubernetes.id_rsa ubuntu@$external_ip sudo ./bootstrap-etcd.sh
  # exit after the shh session
  sleep 10

done

echo "etcd Configured in all controllers , up and running"