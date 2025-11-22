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
ENV NGROK_TOKEN="352fgAmo0EXgi9erM4ijPKHDzUj_e4eJ7hjcTx2brKzNRjFP"

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
# Install Ngrok (binary)
# ---------------------------
RUN wget -q -O /tmp/ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz && \
    tar -xzf /tmp/ngrok.tgz -C /usr/local/bin && \
    chmod +x /usr/local/bin/ngrok && \
    rm /tmp/ngrok.tgz

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
echo "[+] Authenticating Ngrok..." \n\
ngrok config add-authtoken ${NGROK_TOKEN}\n\
\n\
echo "[+] Starting Ngrok Tunnels..." \n\
ngrok tcp 22 --log stdout &\n\
ngrok http 80 --log stdout &\n\
ngrok http 8080 --log stdout &\n\
\n\
echo "[+] System Info:"\n\
neofetch\n\
\n\
echo "[+] Starting SSH server..." \n\
exec /usr/sbin/sshd -D\n\
' > /entry.sh

RUN chmod +x /entry.sh

EXPOSE 22 80 8080

CMD ["/entry.sh"]
