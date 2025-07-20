#!/bin/bash

# 提示用户输入sudo密码
echo "[请求sudo权限]"
sudo -v

if [ $? -ne 0 ]; then
    echo "[请求sudo权限失败]"
    exit 1
fi

wget --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software'   https://www.segger.com/downloads/jlink/JLink_Linux_arm64.deb

sudo dpkg -i JLink_Linux_arm64.deb

sudo apt -y update && sudo apt -y upgrade

echo "[创建systemd服务文件]"

sudo bash -c "cat >> /etc/systemd/system/jlink.service" << EOF
[Unit]
After=network.target

[Service]
ExecStart=/home/radxa/jlink.sh

[Install]
WantedBy=multi-user.target
EOF

sudo bash -c "cat >> /home/radxa/jlink.sh" << EOF
#!/bin/sh
JLinkRemoteServerCLExe -Port 19020
EOF

sudo chmod +x /home/radxa/jlink.sh

sudo systemctl set-default multi-user.target

sudo rm -rf /lib/systemd/system/getty@.service

sudo bash -c "cat >> /lib/systemd/system/getty@.service" << EOF
#  SPDX-License-Identifier: LGPL-2.1-or-later
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=Getty on %I
Documentation=man:agetty(8) man:systemd-getty-generator(8)
Documentation=http://0pointer.de/blog/projects/serial-console.html
After=systemd-user-sessions.service plymouth-quit-wait.service getty-pre.target
After=rc-local.service

# If additional gettys are spawned during boot then we should make
# sure that this is synchronized before getty.target, even though
# getty.target didn't actually pull it in.
Before=getty.target
IgnoreOnIsolate=yes

# IgnoreOnIsolate causes issues with sulogin, if someone isolates
# rescue.target or starts rescue.service from multi-user.target or
# graphical.target.
Conflicts=rescue.service
Before=rescue.service

# On systems without virtual consoles, don't start any getty. Note
# that serial gettys are covered by serial-getty@.service, not this
# unit.
ConditionPathExists=/dev/tty0

[Service]
# the VT is cleared by TTYVTDisallocate
# The '-o' option value tells agetty to replace 'login' arguments with an
# option to preserve environment (-p), followed by '--' for safety, and then
# the entered username.
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin radxa %I $TERM
Type=idle
Restart=always
RestartSec=0
UtmpIdentifier=%I
TTYPath=/dev/%I
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
IgnoreSIGPIPE=no
SendSIGHUP=yes

# Unset locale for the console getty since the console has problems
# displaying some internationalized messages.
UnsetEnvironment=LANG LANGUAGE LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION

[Install]
WantedBy=getty.target
DefaultInstance=tty1
EOF

sudo passwd -d radxa

echo "[脚本运行完毕]"
