
# Firewall Script
# Developed only for my lab tests

version: 2015112401

Created by Matheus Carino

Instructions:

1. Clone the repository.
2. Create a symbolic link of firewall.sh file on the /etc/init.d/ directory.
3. Copy the systemd/firewall.service file on the /etc/systemd/system/ directory.
4. Enable the firewall.service with systemctl.
# sudo systemctl enable firewall.service
5. Start the firewall.service.
# systemctl start firewall.service
6. Check the active rules.
# iptables -nL && iptables -nL -t nat

Questions? Email me. =) Enjoy.
