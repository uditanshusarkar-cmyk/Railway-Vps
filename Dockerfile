FROM ubuntu:22.04

# ---------------------------
# System Update
# ---------------------------
RUN apt update -y && apt upgrade -y

# ---------------------------
# Environment Variables
# ---------------------------
ENV ROOT_PASS="root"
ENV CF_TUNNEL_TOKEN="eyJhIjoiODRjODY1MGE2ZWIzOWE3YzQ5N2ExY2Q1ZDUwODAyM2YiLCJ0IjoiMjg1Mjg2OTQtYzkyYS00M2U4LWE1M2ItMGVmMWZhMjkxZmU1IiwicyI6Ik16Wm1abVl6T1RVdE0yVXpOUzAwT1dReUxUa3dZemN0WldVd016TTJaREZoWWpFMiJ9"

# ---------------------------
# Install Packages
# ---------------------------
RUN apt install -y sudo openssh-server wget unzip curl git make nano htop

RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------------------------
# Install Cloudflared
# ---------------------------
RUN mkdir -p --mode=0755 /usr/share/keyrings && \
    curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg \
        | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' \
        | tee /etc/apt/sources.list.d/cloudflared.list && \
    apt update && apt install -y cloudflared

# ---------------------------
# Install Neofetch
# ---------------------------
RUN apt install -y neofetch

# ---------------------------
# SSH Config
# ---------------------------
RUN mkdir -p /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# ---------------------------
# Entry Script (NO SYSTEMD)
# ---------------------------
RUN printf '#!/bin/bash\n\
echo "root:${ROOT_PASS}" | chpasswd\n\
\n\
# Start Cloudflare Tunnel manually\n\
cloudflared tunnel run --token $CF_TUNNEL_TOKEN &\n\
\n\
# Show system info\n\
neofetch\n\
\n\
# Start SSH server\n\
exec /usr/sbin/sshd -D\n' > /entry.sh

RUN chmod +x /entry.sh

EXPOSE 22
CMD ["/entry.sh"]
