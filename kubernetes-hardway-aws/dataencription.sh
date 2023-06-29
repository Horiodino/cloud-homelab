# the Data Encryption Config and Key
# Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to encrypt cluster data at rest.

# generate an encryption key:
#  this key will be used to encrypt and decrypt the data stored in the etcd
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
# it is using the head command to get the first 32 bytes of the urandom file and then it is using the base64 command to encode the data in base64 format


# // create a file for the encryption config

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

# the above yaml file is creating a encryption config for the kubernetes cluster
# explanation of the above yaml file:
# kind: EncryptionConfig : it is the kind of the resource
# apiVersion: v1 : it is the api version of the resource
# resources: it is the list of the resources that will be encrypted

# -secret : it is the resource that will be encrypted
# providers: it is the list of the providers that will be used to encrypt the data
# -aescbc : it is the provider that will be used to encrypt the data its a algorithm
# keys: it is the list of the keys that will be used to encrypt the data
# -name: key1 : it is the name of the key
# secret: ${ENCRYPTION_KEY} : it is the secret of the key that will be used to encrypt the data
# -identity: {} : dont know about this one :(



for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=${instance}" \
    "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  
  scp -i kubernetes.id_rsa encryption-config.yaml ubuntu@${external_ip}:~/
done

# the above for loop is copying the encryption-config.yaml file to the controller nodes
#  and its coping only in the controller nodes because the encryption key is only needed by the controller nodes
# as the controller nodes are the one who are responsible for encrypting and decrypting the data
