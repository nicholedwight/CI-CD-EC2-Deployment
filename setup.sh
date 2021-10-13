#!/bin/bash
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
sudo mv index.html /var/www/html/index.html
sudo systemctl restart httpd