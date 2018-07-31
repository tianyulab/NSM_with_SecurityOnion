#!/bin/bash

# 下载 & 安装 SiLKWeb
wget https://github.com/tianyulab/NSM_with_SecurityOnion/raw/master/Scripts/silkweb_1.81-1.deb
sudo dpkg -i silkweb_1.81-1.deb

# Apache启用cgi支持
sudo a2enconf serve-cgi-bin
sudo a2enmod cgid
sudo systemctl restart apache2.service

# 复制相关配置
sudo cp -a /var/www/html/silk /var/www/so/
sudo cp -a /usr/lib/cgi-bin /var/www/so/

# 访问SiLKWeb
https://SO/silk


# 参考资料：
# SilkWeb项目主页：https://github.com/cmu-sei/SilkWeb
# SilkWeb – Analyze Silk Data Through API and Javascript Frameworks，https://resources.sei.cmu.edu/asset_files/Presentation/2017_017_001_499148.pdf

: '
Top talkers 举例 - 使用rwstats
# 定义变量
export DATA="/data/outweb/2018/07/25/*"

1.以flow records为计算单位，找出07-25日前20个IP
rwstats --fields=sip --count=20 $DATA

2.以包为计算单位，找出07-25日接收最多包的前20个IP
rwstats --fields=sip --values=packets --count=20 $DATA

3.以byte为单位，找出流量≥100,000,000 bytes的IP组
rwstats --fields=sip,dip --values=byte --threshold=100000000 $DATA

4.以包为计算单位，按照降序方式，找出07-25日的连接记录
rwstats --fields=sip,dip,sport,dport --values=packets --top --threshold=50000 $DATA | more

5.目的端口统计
rwstats --fields=dport --percentage=1 $DATA

6.协议统计
rwstats --fields=protocol --count=10 $DATA


cat << EndOfMessage
This is line 1.
This is line 2.
Line 3.
EndOfMessage

<<COMMENT1
    your comment 1
    comment 2
    blah
COMMENT1
