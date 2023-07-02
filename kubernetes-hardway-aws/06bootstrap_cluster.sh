#  send  autobootstrapcluster.sh to all the controllers 
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa  autobootstrapcluster.sh ubuntu@$external_ip:~/
  ssh -i kubernetes.id_rsa ubuntu@$external_ip sudo chmod +x autobootstrapcluster.sh

  sleep 10
  ssh -i kubernetes.id_rsa ubuntu@$external_ip sudo ./autobootstrapcluster.sh

  sleep 10

done


external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=controller-0" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

# ssh into the first controller and run the following commands

# Create the system:kube-apiserver-to-kubelet ClusterRole with permissions to access the Kubelet API and perform most common tasks associated with managing pods:

ssh -i kubernetes.id_rsa ubuntu@${external_ip} cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

# then apply another file

sleep 10

ssh -i kubernetes.id_rsa ubuntu@${external_ip} cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF   | exit 

# Verification of cluster public endpoint
# The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the compute instances.
# Retrieve the kubernetes-the-hard-way Load Balancer address:

KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')

# Make a HTTP request for the Kubernetes version info:

curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}/version