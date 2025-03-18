#!/bin/sh -e

DIRNAME=`dirname $0`
cd $DIRNAME
USAGE="$0 [ -y | -Y | --yes ]"

# Check for auto-approve flag
AUTO_APPROVE=false
if [ "$1" = "-y" ] || [ "$1" = "-Y" ] || [ "$1" = "--yes" ]; then
    AUTO_APPROVE=true
fi

# Ensure the script is running as root or with sudo
if [ `id -u` != 0 ]; then
    echo "This script requires root privileges. Please run with sudo:"
    echo "sudo $0"
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
sudo mkdir -p /etc/systemd/system/amazon-cloudwatch-agent.service.d

# Create the override file with the Environment variable
cat <<EOF | sudo tee /etc/systemd/system/amazon-cloudwatch-agent.service.d/override.conf
[Service]
Environment="RUN_WITH_SELINUX=True"
EOF

# Reload systemd
sudo systemctl daemon-reload

# Check if auto-approve is enabled, otherwise ask the user
if [ "$AUTO_APPROVE" = true ]; then
    echo "Auto-approve enabled. Restarting CloudWatch Agent..."
    sudo systemctl restart amazon-cloudwatch-agent
    echo "CloudWatch Agent has been restarted."
else
    read -p "Would you like to restart the CloudWatch Agent now? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        sudo systemctl restart amazon-cloudwatch-agent
        echo "CloudWatch Agent has been restarted."
    else
        echo "CloudWatch Agent was not restarted. Please restart it manually using: sudo systemctl restart amazon-cloudwatch-agent"
    fi
fi