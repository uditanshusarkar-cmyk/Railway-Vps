
FROM ubuntu:22.04

# ---------------------------
# System Update
# ---------------------------
RUN apt update -y && apt upgrade -y

# ---------------------------
# Environment Variables
# ---------------------------
ENV ROOT_PASS="root"

# ---------------------------
# Install Required Packages
# ---------------------------
RUN apt install -y sudo openssh-server wget unzip curl git make nano htop

# Allow root & sudo group passwordless sudo
RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------------------------
# Install Cloudflared
# ---------------------------
RUN mkdir -p --mode=0755 /usr/share/keyrings && \
    curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' \
        | tee /etc/apt/sources.list.d/cloudflared.list && \
    apt update && apt install -y cloudflared

# ---------------------------
# Cloudflare Tunnel Install
# ---------------------------
RUN cloudflared service install \
    'eyJhIjoiODRjODY1MGE2ZWIzOWE3YzQ5N2ExY2Q1ZDUwODAyM2YiLCJ0IjoiMjg1Mjg2OTQtYzkyYS00M2U4LWE1M2ItMGVmMWZhMjkxZmU1IiwicyI6Ik16Wm1abVl6T1RVdE0yVXpOUzAwT1dReUxUa3dZemN0WldVd016TTJaREZoWWpFMiJ9'

# ---------------------------
# Install Neofetch
# ---------------------------
RUN apt install -y neofetch

# ---------------------------
# SSH Configuration
# ---------------------------
RUN mkdir -p /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# ---------------------------
# HEALTHCHECK
# ---------------------------
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=5 \
 CMD echo "OK"

# ---------------------------
# ENTRY SCRIPT
# ---------------------------
RUN printf '#!/bin/bash\n\
echo "root:${ROOT_PASS}" | chpasswd\n\
\n\
# Start Cloudflare Tunnel\n\
systemctl enable cloudflared.service || true\n\
systemctl start cloudflared.service || true\n\
\n\
# Show system info\n\
neofetch\n\
\n\
# Start SSH\n\
exec /usr/sbin/sshd -D\n' > /entry.sh

RUN chmod +x /entry.sh

EXPOSE 22
CMD ["/entry.sh"]
