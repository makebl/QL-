#!/usr/bin/env bash
stty erase ^H
PORT=0
#判断当前端口是否被占用，没被占用返回0，反之1
function Listening {
   TCPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l`
   UDPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l`
   (( Listeningnum = TCPListeningnum + UDPListeningnum ))
   if [ $Listeningnum == 0 ]; then
       echo "0"
   else
       echo "1"

}

#指定区间随机数
function random_range {
   shuf -i $1-$2 -n1
}

#得到随机端口
function get_random_port {
   templ=0
   while [ $PORT == 0 ]; do
       temp1=`random_range $1 $2`
       if [ `Listening $temp1` == 0 ] ; then
              PORT=$temp1
       fi
   done
   echo "port=$PORT"
}

TIME() {
  [[ -z "$1" ]] && {
    echo -ne " "
  } || {
    case $1 in
    r) export Color="\e[31;1m" ;;
    g) export Color="\e[32;1m" ;;
    b) export Color="\e[34;1m" ;;
    y) export Color="\e[33;1m" ;;
    z) export Color="\e[35;1m" ;;
    l) export Color="\e[36;1m" ;;
    esac
    [[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
      echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
    }
  }
}

[[ ! "$USER" == "root" ]] && {
  echo
  TIME y "警告：请使用root用户操作!~~"
  echo
  exit 1
}

if [[ "$(. /etc/os-release && echo "$ID")" == "centos" ]]; then
  export Aptget="yum"
  yum -y update
  yum install -y sudo wget curl psmisc
  export XITONG="cent_os"
elif [[ "$(. /etc/os-release && echo "$ID")" == "ubuntu" ]]; then
  export Aptget="apt-get"
  apt-get -y update
  apt-get install -y sudo wget curl psmisc
  export XITONG="ubuntu_os"
elif [[ "$(. /etc/os-release && echo "$ID")" == "debian" ]]; then
  export Aptget="apt"
  apt-get -y update
  apt-get install -y sudo wget curl psmisc
  export XITONG="debian_os"
else
  echo

fi

dir='jd-qinglong'
echo "请指定保存数据的目录，已存在的请指定名字，回车默认jd-qinglong"
read input
if [ -z "${input}" ]; then
  input=$dir
fi
dir=$input

if [ ! -d $dir ]; then
  mkdir $dir
fi

cd $dir || exit

rm -f adbot/adbot

file=env.properties
if [ ! -f "$file" ]; then
  wget -O env.properties https://ghproxy.com/https://raw.githubusercontent.com/rubyangxg/jd-qinglong/master/env.template.properties
else
  echo "env.properties已存在"
fi

docker rm -f webapp
docker pull rubyangxg/jd-qinglong

ad_port1=5701
echo "请设置阿东网页登录端口：(数字5701~65535)，回车默认5703"
while [ 1 ]; do
  read input
  if [ -z "${input}" ]; then
    input=5703
  fi
  if [ $input -gt 5700 -a $input -lt 65536 ]; then
    grep_port=$(netstat -tlpn | grep "\b$input\b")
    if [ -n "$grep_port" ]; then
      get_random_port 5703 5800
      ad_port1=$PORT
      echo -e "端口 $input 已被占用，生成随机端口$ad_port1，配置成功\n"
    else
      echo -e "端口 $input 未被使用，配置成功\n"
      ad_port1=$input
    fi
    break
  else
    echo "别瞎搞，请输入端口：(数字5703~65535)"
  fi
done

ad_port2=5704
echo "请设置阿东网页管理(内部使用)端口：(数字5704~65535)，回车默认5702"
while [ 1 ]; do
  read input
  if [ -z "${input}" ]; then
    input=5704
  fi
  if [ $input -gt 5703 -a $input -lt 65536 ]; then
    grep_port=$(netstat -tlpn | grep "\b$input\b")
    if [ -n "$grep_port" ]; then
      get_random_port 5704 5800
      ad_port2=$PORT
      echo -e "端口 $input 已被占用，生成随机端口$ad_port2，配置成功\n"
    else
      echo -e "端口 $input 未被使用，配置成功\n"
      ad_port2=$input
    fi
    break
  else
    echo "别瞎搞，请输入端口：(数字5704~65535)"
  fi
done

docker run -d -p $ad_port1:8080 -p $ad_port2:8090 --name=webapp --privileged=true -v "$(pwd)"/env.properties:/env.properties:rw -v "$(pwd)"/adbot:/adbot rubyangxg/jd-qinglong

while [ 1 ]; do
  if [ -f "./adbot/adbot" ]; then
    sleep 1s
    echo "阿东启动成功"
    break
  else
    echo "等待阿东启动完成，生成必要文件"
    sleep 1s
  fi
done

json='{"server_groups":[{"name":"webapp","disabled":false,"json":false,"urls":["ws://localhost:'$ad_port1'/ws/cq/"],"event_filter":[],"regex_filter":"","regex_replace":"","extra_header":{"User-Agent":["GMC"]}},{"name":"webapp_admin","disabled":false,"json":false,"urls":["ws://localhost:'$ad_port2'/ws/cq/"],"event_filter":[],"regex_filter":"","regex_replace":"","extra_header":{"User-Agent":["GMC"]}}]}'
echo $json >./adbot/gmc_config.json

cd adbot || exit
chmod +x adbot

echo "请创建一个机器人管理页面用户名：(字母数字下划线)，回车默认admin"
while [ 1 ]; do
  read input
  if [ -z "${input}" ]; then
    input="admin"
  fi
  if [[ $input =~ ^[A-Za-z0-9_]+$ ]]; then
    username=$input
    break
  else
    echo "别瞎搞，请输入用户名：(字母数字下划线)，回车默认随机字符"
  fi
done

echo "请设置机器人管理页面密码：(字母数字下划线)，回车默认adbotadmin"
while [ 1 ]; do
  read input
  if [ -z "${input}" ]; then
    input="adbotadmin"
  fi
  if [[ $input =~ ^[A-Za-z0-9_]+$ ]]; then
    password=$input
    break
  else
    echo "别瞎搞，请输入密码：(字母数字下划线)，回车默认随机字符"
  fi
done

killall adbot

port=8100
echo "请设置机器人管理页面登录端口：(数字8100~65535)，回车默认8100"
while [ 1 ]; do
  read input
  if [ -z "${input}" ]; then
    input=8100
  fi
  if [ $input -gt 8099 -a $input -lt 65536 ]; then
    grep_port=$(netstat -tlpn | grep "\b$input\b")
    if [ -n "$grep_port" ]; then
      get_random_port 8100 8200
      port=$PORT
      echo -e "端口 $input 已被占用，生成随机端口$port，配置成功\n"
    else
      echo -e "端口 $input 未被使用，配置成功\n"
      port=$input
    fi
    break
  else
    echo "别瞎搞，请输入端口：(数字8100~65535)"
  fi
done

echo "你的用户名是$username"
echo "你的密码是$password"
echo "你的机器人管理页面端口是$port"
echo "阿东网页登录端口$ad_port1"
echo "阿东隐藏管理端口(内部使用，不要暴露外网)$ad_port2"

sed -i "s#^username=.*#username=$username#g" ./start-adbot.sh
sed -i "s#^password=.*#password=$password#g" ./start-adbot.sh
sed -i "s#^port=.*#port=$port#g" ./start-adbot.sh

chmod +x ./start-adbot.sh
bash ./start-adbot.sh restart

hasError1=1
for i in {1..10}; do
  urlstatus=$(curl -s -m 5 -IL http://localhost:$ad_port1 | grep 200)
  if [ "$urlstatus" == "" ]; then
    echo "检查是否可访问阿东页面...第 $i 次(共10次)"
    sleep 5s
  else
    hasError1=0
    break
  fi
done

hasError2=1
for i in {1..10}; do
  urlstatus=$(curl -u $username:$password -s -m 5 -IL http://localhost:$port | grep 200)
  if [ "$urlstatus" == "" ]; then
    echo "检查是否可访问机器人管理页面...第 $i 次(共10次)"
    sleep 5s
  else
    hasError2=0
    break
  fi
done

if [ $hasError1 == 1 -o $hasError2 == 1 ]; then
  echo "出错了，请联系作者，查看日志docker logs -f webapp"
else
  sed -i '/^ADONG.URL.*/d' ../env.properties
  sed -i '$aADONG.URL=http://localhost:'$ad_port1'' ../env.properties
  echo "恭喜你安装完成，阿东网页：http://localhost:$ad_port1，阿东机器人登录入口：http://localhost:$port，外部访问请打开防火墙并且开放 $ad_port1 和 $port 端口！"
fi

#bash <(curl -s -L https://ghproxy.com/https://raw.githubusercontent.com/rubyangxg/jd-qinglong/master/install.sh)
#sed -e '0,/localhost:[0-9]\+/ s/localhost:[0-9]\+/localhost:1245/' ./adbot/gmc_config.json
#tac ./adbot/gmc_config.json | sed -e '0,/localhost:[0-9]\+/{s/localhost:[0-9]\+/localhost:1245/}' | tac | tee a.json
