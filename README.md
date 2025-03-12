## AMAZON-CLOUDWATCH-AGENT-SELINUX POLICY

###### Note - We provide a base SELinux policy that allows basic Amazon-CloudWatch-agent functionality. If users want more permissions, then they should review the SELinux documentation to understand how to update the policy to allow additional access, and scope it appropriately for their use case.
###### Note - This policy has been tested to work on AL2 and AL2023 only for now. Please make sure that the OS you are using is AL2 or AL2023.

This is the SELinux policy for AWS CWA agent. Install this policy to confine your CloudWatch Agent processes.

## Installation instructions

###### Note - It is recommended to start SELinux in permissive mode before enabling it in enforcement mode.

Make sure Amazon CWA agent service is installed and running before compiling and installing the SELinux policy:
```
sudo yum install amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
```

Run the following commands:
```
sudo yum update
sudo yum install policycoreutils-devel rpm-build git
```

To build and install the SELinux policy, make sure that SELinux config file is in `permissive` or `enforcing` mode in `/etc/selinux/config` file:
```
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=enforcing
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```
Clone the repository, build and install using the commands below:

```
git clone https://github.com/aws/amazon-cloudwatch-agent-selinux.git
cd amazon-cloudwatch-agent-selinux
chmod +x amazon_cloudwatch_agent.sh
sudo ./amazon_cloudwatch_agent.sh
```
If you need to enable it, please enable the repository, reboot the instance, and verify that it is in either enforcing or permissive mode, depending on your selection.

Otherwise, you can simply restart the agent to ensure it runs in the confined context.

```
sudo systemctl restart amazon-cloudwatch-agent
```

Run `sudo sestatus` in order to see if SELinux is enabled:

```
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31

```
List the CWA processes to check that they are confined:

```

ps -efZ | grep -i amazon

system_u:system_r:amazon_cloudwatch_agent_t:s0 root 5665  1  0 00:15 ?        00:00:02 /usr/bin/amazon-cloudwatch-agent
system_u:system_r:amazon_cloudwatch_agent_t:s0 root 5746 5665  0 00:15 ?      00:00:02 /usr/bin/cloudwatch-agent-worker

```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the GNU GPL v2 License.
