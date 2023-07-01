# Data Encription is required because kubernetes stores a variety of data including cluster state, application configuration, and secrets. Kubernetes supports the ability to encrypt cluster data at rest.
# which means that even if someone gets access to the etcd server, they won't be able to read the data without the encryption key.

# this script is going to generate an encryption key and distribute it to the three controller instances.
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# Encryption Config File
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}  
      - identity: {}
EOF


for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
  scp -i kubernetes.id_rsa encryption-config.yaml ubuntu@${external_ip}:~/
done