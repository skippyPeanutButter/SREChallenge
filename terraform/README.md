# Architecture

<img src=architecture.png alt="architecture diagram">


### What does it all mean?

Terraform will spin up an AWS ELB, an autoscaling group, launch configurations
which make up the webserver instances, security groups, ssh-keys and tie them
all together.

The elastic load balancer will act as a user facing endpoint. This endpoint
will sit in front of the webserver instances and forward traffic to them using
http and https. The load balancer is configured with a self-signed cert for
encrypting traffic between the browser and the traffic between the elb and the
instances are sent in plain text. The ELB periodically befores a health check
of all the instances its configured to forward traffic to, if any of them fail
the check then they are removed from the ELB.

The autoscaling group is responsible for recreating webserver instances that
are consistently failing the ELB health checks and adding them to the load
balancer. It is also responsible spinning up additional instances when the
CPU utilization passes 70% twice within 2 minutes via an autoscaling policy to
handle increased loads.

The launch configuration make up the webserver instances. The launch
configuration executes a user-data script when a new EC2 instance is spun up.
The user-data downloads and executes Ansible to install apache2 and copy over
the necessary configuration files that enables apache to redirect any client
requests received from the load balancer on port 80 to port 443. The script
then downloads and runs goss to do validation of the infrastructure
configuration.

### Prerequisites

In order to create all of the above infrastructure, you'll need an
[AWS](https://aws.amazon.com/console/) account along with an IAM user account
with the proper authorization to create various EC2 resources (autoscaling
groups, elastic load balancer, security groups, etc).

For the sake of simplicity you can create an [AWS free tier
account](https://aws.amazon.com/free/) , create an administrative user, and
generate access keys for this user: [see
docs](https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key/)

> Not responsible for any of the charges you may incur while having fun :)

Once this is done you'll need to specific the following environment variables.
This is what will allow terraform to communicate with AWS on your behalf and
create the necessary infrastructure.

```
export AWS_ACCESS_KEY_ID=<access_key_id>
export AWS_SECRET_ACCESS_KEY=<secret_access_key>
```

The following tools will also need to be installed and available in your
system's `PATH` environment variable.

Install the following the tools:

> The versions used on my local machine are included for completeness.

[AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
<br>Version: aws-cli/1.16.67 Python/2.7.15 Darwin/16.7.0 botocore/1.12.57

[Terraform](https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_darwin_amd64.zip)
<br>Version: 0.11.10

[JQ](https://github.com/stedolan/jq/releases/download/jq-1.5/jq-osx-amd64)
<br>Version: jq-1.5

### Fully automated approach

The entire cluster can be spun up by running the `provision.sh` script.
Before running the script, there are some tools that will required in order for
the script to function correctly.

Please run the following commands to make sure you have the necessary tools
installed and in your `PATH` environment variable.

```bash
aws --version
jq --version
terraform --version
openssl version

# check env vars
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
```

Once all of the above is good to go, execute `./provision.sh`

`provision.sh` will do the following:

1. Check to see if all of the necessary command-line tools are installed
2. Generate a self-signed x509 server certificate and upload it to AWS IAM
3. Retrieve the ARN of the uploaded cert and insert it in `elb.tf` as the ssl_certificate_id property
4. Generate an ssh RSA keypair, the key pair will be added to the launch configuration
5. terraform init/plan/apply the infrastructure (automatically with auto-approve)
6. Retrieve the ELB dns name and run a health check against the DNS_NAME/test.html endpoint
7. Alert you when the endpoint returns a 200 indicating that the service is up.

Once the script successfully finishes you can visit the homepage and view the
hello world page.

To teardown the infrastructure and remove the certs/keys, execute the `cleanup.sh`
script.

### Partially automated setup

Due to the differences between various command-line tools (BSD vs GNU) on
different systems (sed, curl, openssl, aws-cli, etc). The fully automated
approach above may not function as expected for whatever reason.
This partially automated approach will cover steps such as self-signed cert
creation, uploading the self-signed cert to IAM via the AWS cli, generating an
ssh key-pair for logging onto the instances.

1. Generate self signed cert

Note: This was created on MacOS Sierra, if using a distro of Linux your particular
openssl options may differ due to GNU vs BSD tool differences.

```bash
openssl genrsa 2048 > privatekey.pem
openssl req -new -key privatekey.pem -out csr.pem -subj "/C=US/ST=Pennsylvania/L=Philadelphia/O=Dummy Corp/OU=Systems/CN=Local Certificate Authority/"
openssl x509 -req -days 365 -in csr.pem -signkey privatekey.pem -out server.crt
```

This should create a self-signed SSL certificate that can be used to configure
SSL on our ELB.

2. Upload cert to AWS IAM

In this instance I opted to call the server cert `elb-cert-x509`, but you can
call it whatever you like as long as it doesn't already exist in your AWS account.

```bash
aws iam upload-server-certificate --server-certificate-name elb-cert-x509 --certificate-body file://server.crt --private-key file://privatekey.pem
```

This should return a JSON string containing the ARN for your uploaded server-cert.

```json
{
    "ServerCertificateMetadataList": [
        {
            "ServerCertificateId": "Derp",
            "ServerCertificateName": "elb-x509",
            "Expiration": "2019-12-03T22:24:10Z",
            "Path": "/",

            "Arn": "<some_ARN>",
            "UploadDate": "2018-12-03T22:25:46Z"
        }
    ]
}
```

Take the arn string and set it as the `ssl_certificate_id` for the `webserver_elb`
resource in `elb.tf`.

3. Generate an SSH RSA key pair

Again, options may differ based on your version of ssh-keygen

```bash
ssh-keygen -t rsa -N "" -f $PWD/ec2-key
```

4. Run Terraform

Execute the following commands to spin up your terraform infrastructure.

> If you face any issues regarding credentials, please make sure you set your
AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables as specified above.

```bash
terraform init
terraform plan
terraform apply
```

Once it completes you should see terraform output the ELB DNS name.

Due to the instances being provisioned via a user-data script, the provisioning
will still be running even though all of the infrastructure is provisioned in
AWS. This includes the apt package installation, the ansible playbook, and the
goss tests.

You can execute this curl check against the ELB DNS NAME, once a 200 is returned
you will know everything is finished provisioning.

```bash
bash -c 'while [[ "$(curl -k -L -s -o /dev/null -w ''%{http_code}'' <ELB_DNS_NAME>/test.html)" != "200" ]]; do echo "waiting for provisioning"; sleep 5; done'
```
