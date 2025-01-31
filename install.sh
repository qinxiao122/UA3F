#!/bin/sh

getcpucore() {
    cputype=$(uname -ms | tr ' ' '_' | tr '[A-Z]' '[a-z]')
    [ -n "$(echo $cputype | grep -E "linux.*armv.*")" ] && cpucore="armv5"
    [ -n "$(echo $cputype | grep -E "linux.*armv7.*")" ] && [ -n "$(cat /proc/cpuinfo | grep vfp)" ] && [ ! -d /jffs/clash ] && cpucore="armv7"
    [ -n "$(echo $cputype | grep -E "linux.*aarch64.*|linux.*armv8.*")" ] && cpucore="armv8"
    [ -n "$(echo $cputype | grep -E "linux.*86.*")" ] && cpucore="386"
    [ -n "$(echo $cputype | grep -E "linux.*86_64.*")" ] && cpucore="amd64"
    if [ -n "$(echo $cputype | grep -E "linux.*mips.*")" ]; then
        mipstype=$(echo -n I | hexdump -o 2>/dev/null | awk '{ print substr($2,6,1); exit}')
        [ "$mipstype" = "0" ] && cpucore="mips-softfloat" || cpucore="mipsle-softfloat"
    fi
}

ckcmd() {
    command -v sh >/dev/null 2>&1 && command -v $1 >/dev/null 2>&1 || type $1 >/dev/null 2>&1
}

cd /root
getcpucore

version=0.3.0
ua3f_tar=ua3f-$version-$cpucore.tar.gz

if id -u shellclash >/dev/null 2>&1; then
    chmod o+w /etc/clash >/dev/null 2>&1
fi
if id -u shellcrash >/dev/null 2>&1; then
    chmod o+w /etc/clash >/dev/null 2>&1
fi

if [ -f "ua3f" ]; then
    rm "ua3f"
    killall ua3f >/dev/null 2>&1
fi

if ! command -v sudo >/dev/null 2>&1; then
    opkg update >/dev/null 2>&1 && opkg install sudo >/dev/null 2>&1
fi

chmod ugo+w /var/log
if [ -f "/var/log/ua3f.log" ]; then
    rm "/var/log/ua3f.log"
fi
touch /var/log/ua3f.log && chmod 666 /var/log/ua3f.log

if [ -f "$ua3f_tar" ]; then
    rm "$ua3f_tar"
fi

wget https://blog.sunbk201.site/cdn/bin/$ua3f_tar
if [ $? -ne 0 ]; then
    echo "Download UA3F Failed, Please Retry."
    exit 1
fi
tar zxf $ua3f_tar && rm -f $ua3f_tar
chmod +x ua3f

if [ -f "/etc/init.d/ua3f.service" ]; then
    rm "/etc/init.d/ua3f.service"
fi
wget https://blog.sunbk201.site/cdn/ua3f.service
if [ $? -ne 0 ]; then
    echo "Download ua3f.service Failed, Please Retry."
    exit 1
fi
mv ua3f.service /etc/init.d/ && chmod +x /etc/init.d/ua3f.service
/etc/init.d/ua3f.service enable

wget https://blog.sunbk201.site/cdn/ua3f.uci
if [ $? -ne 0 ]; then
    echo "Download ua3f.uci Failed, Please Retry."
    exit 1
fi
mv ua3f.uci /etc/config/ua3f

wget https://blog.sunbk201.site/cdn/cbi.lua
if [ $? -ne 0 ]; then
    echo "Download cbi.lua Failed, Please Retry."
    exit 1
fi
mkdir -p /usr/lib/lua/luci/model/cbi
mv cbi.lua /usr/lib/lua/luci/model/cbi/ua3f.lua

wget https://blog.sunbk201.site/cdn/controller.lua
if [ $? -ne 0 ]; then
    echo "Download controller.lua Failed, Please Retry."
    exit 1
fi
mkdir -p /usr/lib/lua/luci/controller
mv controller.lua /usr/lib/lua/luci/controller/ua3f.lua

chmod +x /etc/config/ua3f >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Install UA3F Success."
fi

rm /tmp/luci-modulecache/* >/dev/null 2>&1
rm /tmp/luci-indexcache* >/dev/null 2>&1
service ua3f.service reload >/dev/null 2>&1
