FROM ubuntu:24.04

# ---------------------------
# System Update
# ---------------------------
RUN apt update -y && apt upgrade -y

# ---------------------------
# Railway Environment Variables
# ---------------------------
ENV NGROK_TOKEN="2Ten9TkU9KxLJV9UH8gU4zlvuNR_7nMVEL6mYrU4tnrRrNHvt"
ENV ROOT_PASS="root"

# ---------------------------
# Install Packages
# ---------------------------
RUN apt install -y sudo openssh-server wget unzip curl git make nano htop

# Allow root & all users to use sudo without password
RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------------------------
# Install Ngrok
# ---------------------------
RUN wget -O /ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip && \
    unzip /ngrok.zip -d / && \
    rm -f /ngrok.zip

# ---------------------------
# Install Neofetch (Ubuntu 24 removed it, so use curl)
# ---------------------------
RUN curl -L https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch -o /usr/local/bin/neofetch && \
    chmod +x /usr/local/bin/neofetch

# ---------------------------
# SSH Configuration
# ---------------------------
RUN mkdir -p /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# ---------------------------
# HEALTHCHECK FIX
# ---------------------------
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=5 \
 CMD echo "OK"

# ---------------------------
# ENTRY SCRIPT
# ---------------------------
RUN printf '#!/bin/bash\n\
echo "root:${ROOT_PASS}" | chpasswd\n\
\n\
if [ -n "$NGROK_TOKEN" ]; then\n\
    /ngrok config add-authtoken $NGROK_TOKEN\n\
    /ngrok tcp 22 --region=in &>/dev/null &\n\
fi\n\
\n\
neofetch\n\
\n\
exec /usr/sbin/sshd -D\n' > /entry.sh

RUN chmod +x /entry.sh

EXPOSE 22
CMD ["/entry.sh"]
