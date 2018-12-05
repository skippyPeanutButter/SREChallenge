#!/bin/bash
set -e

check_credentials_are_loaded () {
  if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]
  then
    if [ ! -f "${HOME}/.aws/credentials" ]
    then
      echo "AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY variables not set"
      echo "Please set these environment variables or create a ${HOME}/.aws/credentials file with the appropriate credentials"
      exit 1
    fi
  fi
}

check_tools_are_installed () {
  for tool in aws terraform openssl jq sed curl ssh-keygen;
  do
    if ! type -a $tool > /dev/null; then
      echo "$tool is not installed"
      exit 1
    fi
  done
}

generate_ssl_cert () {
  openssl genrsa 2048 > privatekey.pem
  openssl req -new -key privatekey.pem -out csr.pem -subj "/C=US/ST=Pennsylvania/L=Philadelphia/O=Dummy Corp/OU=Systems/CN=Local Certificate Authority/"
  openssl x509 -req -days 365 -in csr.pem -signkey privatekey.pem -out server.crt
}

check_credentials_are_loaded
check_tools_are_installed
generate_ssl_cert

echo "Uploading self-signed cert to IAM..."
cert_arn=$(aws iam upload-server-certificate --server-certificate-name elb-cert-x509 --certificate-body file://server.crt --private-key file://privatekey.pem | jq '.ServerCertificateMetadata.Arn')

echo "Updating elb ssl certificate id in elb.tf..."
sed -i -e "/ssl_certificate_id =/ s/= .*/= $(echo $cert_arn | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/" elb.tf

echo "Generating key pair"
ssh-keygen -t rsa -N "" -f $PWD/ec2-key

terraform init

terraform plan

terraform apply -auto-approve

dns_name=$(terraform output elb_dns_name)

count=100
while [[ "$(curl -k -L -s -o /dev/null -w ''%{http_code}'' ${dns_name}/test.html)" != "200" ]];
do
  if [ "${count}" -eq "0" ]; then
    echo "Healthcheck failed, endpoint did not come up"
    exit 1
  fi
  echo "Waiting for system to finish provisioning... ${count}"
  sleep 5
  count=$((count-1))
done

echo "${dns_name} is now ready.."
echo "Please see ${dns_name} for the welcome page!"
echo "Please see ${dns_name}/test.html for the results of the goss tests!"
