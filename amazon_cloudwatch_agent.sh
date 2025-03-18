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
Environment="RUN_WITH_SELINUX=True"
EOF

# Reload systemd
sudo systemctl daemon-reload

# Ask the customer if they want to restart the CloudWatch agent
read -p "Would you like to restart the CloudWatch Agent now? (y/N): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    sudo systemctl restart amazon-cloudwatch-agent
    echo "CloudWatch Agent has been restarted."
else
    echo "CloudWatch Agent was not restarted. Please restart it manually using: systemctl restart amazon-cloudwatch-agent"
fi

echo "Policy loaded. Environment variable applied."
