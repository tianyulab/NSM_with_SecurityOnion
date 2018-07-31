#!/bin/bash

# 安装日志
# exec >  >(tee -a silkinstall.log)
# exec 2> >(tee -a silkinstall.log >&2)

# 安装依赖包
echo "安装依赖包"
sudo apt -y install libglib2.0-dev libpcap-dev python-dev

# 下载CERT NetSA源码包
echo "下载CERT NetSA源码包"
cd ~
mkdir tmp
cd tmp

wget https://tools.netsa.cert.org/releases/silk-3.17.2.tar.gz
wget https://tools.netsa.cert.org/releases/yaf-2.10.0.tar.gz
wget https://tools.netsa.cert.org/releases/libfixbuf-2.1.0.tar.gz

# 安装libfixbuf
echo "安装libfixbuf"
cd ~/tmp
tar -zxvf libfixbuf-2.1.0.tar.gz
cd libfixbuf-2.1.0
./configure && make
sudo make install

# 安装YAF
echo "安装YAF"
cd ~/tmp
tar -zxvf yaf-2.10.0.tar.gz
cd yaf-2.10.0
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
./configure --enable-applabel
make
sudo make install

# 安装SiLK
echo "安装SiLK"
sudo mkdir /data
cd ~/tmp
tar -xvzf silk-3.17.2.tar.gz
cd silk-3.17.2
./configure \
 --with-libfixbuf=/usr/local/lib/pkgconfig/ \
 --with-python \
 --enable-ipv6
make
sudo make install

cat <<EOF >>silk.conf
/usr/local/lib
/usr/local/lib/silk
EOF
sudo mv silk.conf /etc/ld.so.conf.d/

sudo ldconfig

# 配置SiLK
echo "配置SiLK"
cd ~/tmp/silk-3.17.2
sudo cp site/twoway/silk.conf /data

cat <<EOF >sensors.conf
probe S0 ipfix
 listen-on-port 18001
 protocol tcp
 listen-as-host 127.0.0.1
end probe
group my-network
 ipblocks 192.168.100.0/24 # address of eth0. CHANGE THIS.
 ipblocks 10.0.0.0/8 # other blocks you consider internal
end group
sensor S0
 ipfix-probes S0
 internal-ipblocks @my-network
 external-ipblocks remainder
end sensor
EOF
sudo mv sensors.conf /data

# 配置rwflowpack
echo "配置rwflowpack"
cat /usr/local/share/silk/etc/rwflowpack.conf | \
sed 's/ENABLED=/ENABLED=yes/;' | \
sed 's/SENSOR_CONFIG=/SENSOR_CONFIG=\/data\/sensors.conf/;' | \
sed 's/SITE_CONFIG=/SITE_CONFIG=\/data\/silk.conf/' | \
sed 's/LOG_TYPE=syslog/LOG_TYPE=legacy/' | \
sed 's/LOG_DIR=.*/LOG_DIR=\/var\/log/' | \
sed 's/CREATE_DIRECTORIES=.*/CREATE_DIRECTORIES=yes/' \
>> rwflowpack.conf
sudo mv rwflowpack.conf /usr/local/etc/

sudo cp /usr/local/share/silk/etc/init.d/rwflowpack /etc/init.d
sudo sudo update-rc.d rwflowpack start 20 3 4 5 .
sudo service rwflowpack start

# 启动YAF
echo "启动YAF"
sudo nohup /usr/local/bin/yaf --silk --ipfix=tcp --live=pcap  --out=127.0.0.1 \
--ipfix-port=18001 --in=enp3s0 --applabel --max-payload=384 &

################################################ 以下命令为手动执行 #############################################################
# 测试
ping -c4 9.9.9.9
sudo ps -auxww | grep yaf
sudo sh /etc/init.d/rwflowpack status
cat /var/log/rwflowpack-*.log

/usr/local/bin/rwfilter --sensor=S0 --proto=0-255 --pass=stdout --type=all | rwcut | tail

# 参考资料：
# 注意：CERT Linux Forensics Tools Repository 包含RPM包，支持RHEL/CentOS 6/7 和 Fedora 17-28
# 安装指南：https://tools.netsa.cert.org/confluence/pages/viewpage.action?pageId=23298051
# CERT NetSA Security Suite 主页：https://tools.netsa.cert.org/index.html
# CERT Linux Forensics Tools Repository (LiFTeR) 主页：https://forensics.cert.org/repository/
# FlowBAT 安装脚本：https://github.com/chrissanders/FlowBAT/tree/master/support

# Applied Detection and Analysis with Flow Data - Security Onion Con 2014
# https://www.slideshare.net/chrissanders88/applied-detection-and-analysis-with-flow-data-so-con-2014

# NetFlow Analysis Intrusion Detection, Protection
# https://resources.sei.cmu.edu/asset_files/Presentation/2016_017_001_450021.pdf

################################################ 可选项 #############################################################
# 启用Geo国家代码支持
<<comment1
wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip
unzip GeoLite2-Country-CSV.zip
rwgeoip2ccmap --input-path=GeoLite2-Country-CSV_20180703 --output-path=country_codes.pmap
sudo cp country_codes.pmap /usr/local/share/silk/
# 测试：
rwip2cc --address=74.125.67.100
参考：https://tools.netsa.cert.org/silk/rwgeoip2ccmap.html
comment1
