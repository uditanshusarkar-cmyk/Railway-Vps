FROM debian:stable

# ---------------------------
# System Update
# ---------------------------
RUN apt update -y > /dev/null 2>&1 && \
    apt upgrade -y > /dev/null 2>&1

# ---------------------------
# Railway Environment Variables
# ---------------------------
ENV NGROK_TOKEN="2Ten9TkU9KxLJV9UH8gU4zlvuNR_7nMVEL6mYrU4tnrRrNHvt"
ENV ROOT_PASS="root"

# ---------------------------
# Install Packages
# ---------------------------
RUN apt install -y openssh-server wget unzip curl > /dev/null 2>&1

# ---------------------------
# Install Ngrok
# ---------------------------
RUN wget -O /ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip > /dev/null 2>&1 && \
    unzip /ngrok.zip -d / && \
    rm -f /ngrok.zip

# ---------------------------
# SSH Configuration
# ---------------------------
RUN mkdir -p /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "ClientAliveInterval 120" >> /etc/ssh/sshd_config && \
    echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config

# ---------------------------
# HEALTHCHECK FIX (Important)
# Prevent Railway from marking container unhealthy
# ---------------------------
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=5 \
 CMD echo "OK"

# ---------------------------
# ENTRY SCRIPT
# ---------------------------
RUN printf '#!/bin/bash\n\
\n\
# Set root password from Railway variable\n\
echo "root:${ROOT_PASS}" | chpasswd\n\
\n\
# Start ngrok TCP if token exists\n\
if [ -n "$NGROK_TOKEN" ]; then\n\
    /ngrok config add-authtoken $NGROK_TOKEN\n\
    /ngrok tcp 22 --region=in &>/dev/null &\n\
fi\n\
\n\
# Print ngrok logs to Railway console\n\
tail -F /root/.ngrok2/ngrok.log &\n\
\n\
# Start SSH in foreground\n\
exec /usr/sbin/sshd -D\n' > /entry.sh

RUN chmod +x /entry.sh

EXPOSE 22
CMD ["/entry.sh"]
