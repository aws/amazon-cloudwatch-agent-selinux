#!/bin/sh -e

DIRNAME=`dirname $0`
cd $DIRNAME
USAGE="$0 [ --update ]"
if [ `id -u` != 0 ]; then
    echo 'You must be root to run this script'
    exit 1
fi

echo "Building and Loading Policy"
set -x
make -f /usr/share/selinux/devel/Makefile amazon_cloudwatch_agent.pp || exit
/usr/sbin/semodule -i amazon_cloudwatch_agent.pp

# Fixing the file context on CloudWatch agent files
/sbin/restorecon -R -v /opt/aws/amazon-cloudwatch-agent || true
/sbin/restorecon -v /etc/systemd/system/amazon-cloudwatch-agent.service || true

echo "Adding environment variable to systemd service"

# Ensure the directory exists
mkdir -p /etc/systemd/system/amazon-cloudwatch-agent.service.d

# Create the override file with the Environment variable
cat <<EOF | tee /etc/systemd/system/amazon-cloudwatch-agent.service.d/override.conf
[Service]
Environment="CWAGENT_DEBUG=true"
EOF

# Reload systemd and restart the CloudWatch agent
systemctl daemon-reload
systemctl restart amazon-cloudwatch-agent

echo "Policy loaded. CloudWatch agent should be restarted with the new environment variable: systemctl restart amazon-cloudwatch-agent"