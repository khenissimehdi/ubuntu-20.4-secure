#!/bin/bash

# Define username
USERNAME=""

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Update and upgrade packages
apt-get update && apt-get upgrade -y

# Install fail2ban
apt-get install -y fail2ban

# Create user with specified groups, shell, and add to sudoers without password
adduser --disabled-login --shell /bin/bash --gecos "" "$USERNAME"
usermod -a -G users,sudo $USERNAME
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add the public SSH key to the authorized_keys
mkdir -p /home/$USERNAME/.ssh
echo "" > /home/$USERNAME/.ssh/authorized_keys
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh



# Configure fail2ban
echo "[sshd]" > /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
echo "banaction = iptables-multiport" >> /etc/fail2ban/jail.local

# Enable and start fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Restart SSH service to apply changes
systemctl restart sshd

# Optionally, reboot the system at the end of the script
reboot

# SSHD Configurations

echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config

echo "Configuration complete."
