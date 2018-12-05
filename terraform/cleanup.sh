#!/bin/bash

echo "Tearing down infrastructure..."
terraform destroy

echo "Removing generated key pair..."
rm ec2-key ec2-key.pub

echo "Removing old certifcate files..."
rm privatekey.pem csr.pem server.crt

# cleanup self-signed server certificate
echo "Removing self-signed server certificate elb-cert-x509..."
aws iam delete-server-certificate --server-certificate-name elb-cert-x509
