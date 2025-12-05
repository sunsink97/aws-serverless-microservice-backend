#!/bin/bash
set -xe

LOG_FILE="/var/log/user-data.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "========== USER DATA START =========="

log "STEP 1 START - dnf update and install nginx + agents"

dnf update -y >> "$LOG_FILE" 2>&1

# Install NGINX, CloudWatch Agent, and SSM Agent (AL2023 packages)
dnf install -y nginx amazon-cloudwatch-agent amazon-ssm-agent >> "$LOG_FILE" 2>&1

# Enable & start services
systemctl enable nginx >> "$LOG_FILE" 2>&1
systemctl start nginx >> "$LOG_FILE" 2>&1

systemctl enable amazon-ssm-agent >> "$LOG_FILE" 2>&1
systemctl start amazon-ssm-agent >> "$LOG_FILE" 2>&1

log "STEP 1 END - Packages installed and services started"

log "STEP 2 START - Write index.html"

cat << 'EOF' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
  <head>
    <title>NGINX on EC2</title>
  </head>
  <body>
    <h1>NGINX is running on this EC2 instance</h1>
  </body>
</html>
EOF

log "STEP 2 END - index.html written"

log "STEP 3 START - Configure CloudWatch Agent"

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "InstanceId": "$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ],
        "metrics_collection_interval": 60
      },
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": true
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/ec2/system/messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/ec2/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/ec2/nginx/error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/ec2/userdata",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s >> "$LOG_FILE" 2>&1

log "STEP 3 END - CloudWatch Agent configured and started"

