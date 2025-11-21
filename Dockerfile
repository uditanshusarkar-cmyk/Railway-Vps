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
RUN apt install -y sudo openssh-server wget curl git unzip make nano htop snapd

# ---------------------------
# Create User
# ---------------------------
RUN useradd -m -s /bin/bash $USERNAME && \
    echo "$USERNAME:$USER_PASS" | chpasswd && \
    usermod -aG sudo $USERNAME

# Allow sudo without password
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------------------------
# Install LocalXpose (TunnelX)
# ---------------------------
RUN ln -s /var/lib/snapd/snap /snap || true && \
    snap install core && \
    snap install localxpose

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
# ENTRY SCRIPT (Auto Start)
# ---------------------------
RUN printf '#!/bin/bash\n\
echo "root:${ROOT_PASS}" | chpasswd\n\
echo "${USERNAME}:${USER_PASS}" | chpasswd\n\
\n\
echo "[+] Authenticating LocalXpose..."\n\
localxpose authtoken $LX_TOKEN\n\
\n\
echo "[+] Starting LocalXpose tunnels..."\n\
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
