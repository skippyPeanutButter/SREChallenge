# Provisioning with Ansible

For provisioning the web server instances I utilize
[Ansible](https://www.ansible.com/). I wrote a simple role that installs the
Apache 2 HTTP server on an Ubuntu Linux system, enables the rewrite module,
copies an index.html, and copies a custom Apache config file that redirects any
HTTP requests it receives on port 80 to HTTPs on port 443.

Note: The ansible provisioning and goss testing tools are installed and
executed as part of the user-data launch configuration whenever a new web
server instance is spun up. The user-data script will continue running even
after the infrastructure is provisioned, so there will be a delay between
terraform completing and the server endpoint being fully available. Once the
user-data scripts finishes executing, the goss test results are written to the
`<ELB_DNS_NAME>/tests.html` endpoint and can be viewed in the browser.

### Testing with Goss

For testing my infrastructure configuration I utilized
[goss](https://github.com/aelsabbahy/goss). The goss binary is downloaded onto
each provisioned web server instance and the instance configuration is validated
against the [goss.yaml spec](./tests/goss.yaml).
