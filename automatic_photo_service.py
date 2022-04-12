[Unit]
Description= automatic picture
After=multi-user.target
StartLimitIntervalSec=200
StartLimitBurst=4

[Service]
ExecStart=/usr/bin/python /home/pi/camera/picture_code.py
StandardOutput=inherit
StandardError=inherit
Restart=always
RestartSec=20
User=pi
Type=idle

[Install]
WantedBy=multi-user.target