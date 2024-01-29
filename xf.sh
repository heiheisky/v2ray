#!/bin/sh
##

# Set ARG
ARCH="64"
DOWNLOAD_PATH="/tmp/v2ray"

mkdir -p ${DOWNLOAD_PATH}
cd ${DOWNLOAD_PATH} || exit

TAG=$(wget --no-check-certificate -qO- https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)
if [ -z "${TAG}" ]; then
    echo "Error: Get v2ray latest version failed" && exit 1
fi
echo "The v2ray latest version: ${TAG}"

# Download files
V2RAY_FILE="v2ray-linux-${ARCH}.zip"
DGST_FILE="v2ray-linux-${ARCH}.zip.dgst"
echo "Downloading binary file: ${V2RAY_FILE}"
echo "Downloading binary file: ${DGST_FILE}"

# TAG=$(wget -qO- https://raw.githubusercontent.com/v2fly/docker/master/ReleaseTag | head -n1)
wget -O ${DOWNLOAD_PATH}/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${V2RAY_FILE} >/dev/null 2>&1
wget -O ${DOWNLOAD_PATH}/v2ray.zip.dgst https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${DGST_FILE} >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${V2RAY_FILE} ${DGST_FILE}" && exit 1
fi
echo "Download binary file: ${V2RAY_FILE} ${DGST_FILE} completed"

# Check SHA512
LOCAL=$(openssl dgst -sha512 v2ray.zip | sed 's/([^)]*)//g')
STR=$(cat < v2ray.zip.dgst | grep 'SHA2-512' | head -n1)

if [ "${LOCAL}" = "${STR}" ]; then
    echo " Check passed" && rm -fv v2ray.zip.dgst
else
    echo " Check have not passed yet " && exit 1
fi

# Prepare
echo "Prepare to use"
unzip v2ray.zip && chmod +x v2ray
mv v2ray /usr/bin/
mv geosite.dat geoip.dat /usr/local/share/v2ray/
# mv config.json /etc/v2ray/config.json

# Set config file
cat <<EOF >/etc/v2ray/config.json
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 40163,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "b387a58a-a1be-4874-ac26-787a15052c47",
                        "alterId": 0
                    }
                ],
                "disableInsecureEncryption": true
            },
            "streamSettings": {
                "network": "ws"
#                "security": "tls", 
#                "wsSettings": { 
#                    "path": "/2048-end", 
#                    "headers": { "Host": "am-koyeb.cooldoing.com" } 
#                }    
#            }, 
#            "sniffing": { 
#            "enabled": true, 
#            "destOverride": [ "http", 
#                    "tls" 
#                    ] 
#            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
#{ "log": { "access": "/var/log/v2ray/access.log", "error": "/var/log/v2ray/error.log", "loglevel": "warning" }, "dns": {}, "api": { "tag": "api", "services": [ "HandlerService", "LoggerService", "StatsService" ] }, "stats": {}, "policy": { "levels": { "0": { "handshake": 6, "connIdle": 577, "uplinkOnly": 8, "downlinkOnly": 5, "statsUserUplink": true, "statsUserDownlink": true } }, "system": { "statsInboundUplink": true, "statsInboundDownlink": true, "statsOutboundUplink": true, "statsOutboundDownlink": true } }, "routing": { "domainStrategy": "IPIfNonMatch", "rules": [ { "type": "field", "inboundTag": [ "api" ], "outboundTag": "api" }, { "type": "field", "protocol": [ "bittorrent" ], "marktag": "ban_bt", "outboundTag": "block" }, { "type": "field", "ip": [ "geoip:cn" ], "marktag": "ban_geoip_cn", "outboundTag": "block" }, { "type": "field", "ip": [ "geoip:private" ], "outboundTag": "block" } ] }, "inbounds": [ { "tag": "api", "port": 57723, "listen": "127.0.0.1", "protocol": "dokodemo-door", "settings": { "address": "127.0.0.1" } } ], "outbounds": [ { "tag": "direct", "protocol": "freedom" }, { "tag": "block", "protocol": "blackhole" } ] }
EOF
mkdir -p /etc/v2ray/conf
#cat <<EOF >/etc/v2ray/conf/1.json
#{ "inbounds": [ { "tag": "1.json", "port": 40163, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [ { "id": "b387a58a-a1be-4874-ac26-787a15052c47" } ] }, "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "path": "/2048-end", "headers": { "Host": "am-koyeb.cooldoing.com" } } }, "sniffing": { "enabled": true, "destOverride": [ "http", "tls" ] } } ] }
#EOF
# Clean
cd ~ || return
rm -rf ${DOWNLOAD_PATH:?}/*
echo "Install done"

echo "--------------------------------"
echo "Fly App Name: ${FLY_APP_NAME}"
echo "Fly App Region: ${FLY_REGION}"
echo "V2Ray UUID: ${UUID}"
echo "--------------------------------"

# Run v2ray
/usr/bin/v2ray run -config /etc/v2ray/config.json
