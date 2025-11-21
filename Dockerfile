FROM ubuntu:22.04

# ---------------------------
# System Update
# ---------------------------
RUN apt update -y && apt upgrade -y

# ---------------------------
# Environment Variables
# ---------------------------
ENV ROOT_PASS="root"
ENV USERNAME="uditanshu"
ENV USER_PASS="uditanshu"
ENV LX_TOKEN="hCVItCCQ8TfcwMFBuMko4CtHKJ3JxR83GRO71USe"

# ---------------------------
# Essentials
# ---------------------------
RUN apt install -y sudo openssh-server wget curl git unzip make nano htop

# ---------------------------
# Create User
# ---------------------------
RUN useradd -m -s /bin/bash $USERNAME && \
    echo "$USERNAME:$USER_PASS" | chpasswd && \
    usermod -aG sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------------------------
# Install LocalXpose (NO SNAP)
# ---------------------------
RUN wget https://downloads.localxpose.io/localxpose_3.3.0_linux_amd64.deb && \
    apt install -y ./localxpose_3.3.0_linux_amd64.deb && \
    rm localxpose_3.3.0_linux_amd64.deb

# ---------------------------
# Install Neofetch
# ---------------------------
RUN apt install -y neofetch

# ---------------------------
# SSH Config
# ---------------------------
RUN mkdir -p /run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers root $USERNAME" >> /etc/ssh/sshd_config

# ---------------------------
# ENTRY SCRIPT
# ---------------------------
RUN printf '#!/bin/bash\n\
echo "root:${ROOT_PASS}" | chpasswd\n\
echo "${USERNAME}:${USER_PASS}" | chpasswd\n\
\n\
echo "[+] Authenticating TunnelX..."\n\
localxpose authtoken $LX_TOKEN\n\
\n\
echo "[+] Starting TunnelX Tunnels..."\n\
localxpose tcp 22 &\n\
localxpose http 80 &\n\
localxpose http 8080 &\n\
\n\
echo "[+] System Info:"\n\
neofetch\n\
\n\
echo "[+] Starting SSH server..."\n\
exec /usr/sbin/sshd -D\n\
' > /entry.sh

RUN chmod +x /entry.sh

EXPOSE 22 80 8080

CMD ["/entry.sh"]
