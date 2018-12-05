# SRE Challenge

### Challenge

For this project, please think about how you would architect a scalable and
secure static web application in AWS or another IaaS provider.
* Create and deploy a running instance of a web server using a configuration
* management tool of your choice. The web server should serve one page with the
following content.

```html
<html>
<head>
<title>Hello World</title>
</head>
<body>
<h1>Hello World!</h1>
</body>
</html>
```

* Secure this application and host such that only appropriate ports are
  publicly exposed and any http requests are redirected to https. This should
  be automated using a configuration management tool of your choice and you
  should feel free to use a self-signed certificate for the web server.
* Develop and apply automated tests to validate the correctness of the server
  configuration.
* Express everything in code.
* Provide your code in a Git repository named SREChallenge on GitHub.com
* Be prepared to walk though your code, discuss your thought process, and talk
  through how you might monitor and scale this application. You should also be
  able to demo a running instance of the host.

### Solution

This is an infrastructure as code project that utilizes
Terraform/Ansible/Goss/AWS to programmatically configure an autoscaling
WebServer cluster behind an elastic load balancer endpoint to serve up a
scalable, self-healing hello-world application within Amazon Web Services!

For instructions on setting up this cluster in AWS, see the [terraform folder
README](terraform/README.md)

For information on how the web server infrastructure is configured, see the
[ansible folder README](ansible/README.md).
