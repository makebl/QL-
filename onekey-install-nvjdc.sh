#/usr/bin/env bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1
clear
# globals
CWD=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
[ -e "${CWD}/scripts/globals" ] && . ${CWD}/scripts/globals

# import functions
[ -e "/lib/lsb/init-functions" ] && . /lib/lsb/init-functions
[ -e "${CWD}/scripts/functions" ] && . ${CWD}/scripts/functions

checkos(){
  ifTermux=$(echo $PWD | grep termux)
  ifMacOS=$(uname -a | grep Darwin)
  if [ -n "$ifTermux" ];then
    os_version=Termux
  elif [ -n "$ifMacOS" ];then
    os_version=MacOS  
  else  
    os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
  fi
  
  if [[ "$os_version" == "2004" ]] || [[ "$os_version" == "10" ]] || [[ "$os_version" == "11" ]];then
    ssll="-k --ciphers DEFAULT@SECLEVEL=1"
  fi
}
checkos 

checkCPU(){
  CPUArch=$(uname -m)
  if [[ "$CPUArch" == "aarch64" ]];then
    arch=linux_arm64
  elif [[ "$CPUArch" == "i686" ]];then
    arch=linux_386
  elif [[ "$CPUArch" == "arm" ]];then
    arch=linux_arm
  elif [[ "$CPUArch" == "x86_64" ]] && [ -n "$ifMacOS" ];then
    arch=darwin_amd64
  elif [[ "$CPUArch" == "x86_64" ]];then
    arch=linux_amd64    
  fi
}
checkCPU
check_dependencies(){

  os_detail=$(cat /etc/os-release 2> /dev/null)
  if_debian=$(echo $os_detail | grep 'ebian')
  if_redhat=$(echo $os_detail | grep 'rhel')
  if [ -n "$if_debian" ];then
    InstallMethod="apt"
  elif [ -n "$if_redhat" ] && [[ "$os_version" -lt 8 ]];then
    InstallMethod="yum"
  elif [[ "$os_version" == "MacOS" ]];then
    InstallMethod="brew"  
  fi
}
check_dependencies
#安装wget、curl、unzip
${InstallMethod} install unzip wget curl -y > /dev/null 2>&1 
get_opsy() {
  [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
  [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
  [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}
virt_check() {
  # if hash ifconfig 2>/dev/null; then
  # eth=$(ifconfig)
  # fi

  virtualx=$(dmesg) 2>/dev/null

  if [[ $(which dmidecode) ]]; then
    sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
    sys_product=$(dmidecode -s system-product-name) 2>/dev/null
    sys_ver=$(dmidecode -s system-version) 2>/dev/null
  else
    sys_manu=""
    sys_product=""
    sys_ver=""
  fi

  if grep docker /proc/1/cgroup -qa; then
    virtual="Docker"
  elif grep lxc /proc/1/cgroup -qa; then
    virtual="Lxc"
  elif grep -qa container=lxc /proc/1/environ; then
    virtual="Lxc"
  elif [[ -f /proc/user_beancounters ]]; then
    virtual="OpenVZ"
  elif [[ "$virtualx" == *kvm-clock* ]]; then
    virtual="KVM"
  elif [[ "$cname" == *KVM* ]]; then
    virtual="KVM"
  elif [[ "$cname" == *QEMU* ]]; then
    virtual="KVM"
  elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
    virtual="VMware"
  elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
    virtual="Parallels"
  elif [[ "$virtualx" == *VirtualBox* ]]; then
    virtual="VirtualBox"
  elif [[ -e /proc/xen ]]; then
    virtual="Xen"
  elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
    if [[ "$sys_product" == *"Virtual Machine"* ]]; then
      if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
        virtual="Hyper-V"
      else
        virtual="Microsoft Virtual Machine"
      fi
    fi
  else
    virtual="Dedicated母鸡"
  fi
}
get_system_info() {
  cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
  #cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
  #freq=$(awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
  #corescache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
  #tram=$(free -m | awk '/Mem/ {print $2}')
  #uram=$(free -m | awk '/Mem/ {print $3}')
  #bram=$(free -m | awk '/Mem/ {print $6}')
  #swap=$(free -m | awk '/Swap/ {print $2}')
  #uswap=$(free -m | awk '/Swap/ {print $3}')
  #up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d hour %d min\n",a,b,c)}' /proc/uptime)
  #load=$(w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
  opsy=$(get_opsy)
  arch=$(uname -m)
  #lbit=$(getconf LONG_BIT)
  kern=$(uname -r)
  # disk_size1=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' )
  # disk_size2=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' )
  # disk_total_size=$( calc_disk ${disk_size1[@]} )
  # disk_used_size=$( calc_disk ${disk_size2[@]} )
  #tcpctrl=$(sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}')
  virt_check
}
copyright(){
    clear
echo -e "
—————————————————————————————————————————————————————————————
        Nvjdc自助面板一键安装脚本   by 翔翎                      
 ${green}                
        

        

        Faker仓库频道：${plain}${red}https://t.me/pandaqx${plain}   
—————————————————————————————————————————————————————————————
"
}
quit(){
exit
}

install_nvjdc(){
echo -e "${red}开始进行安装,请根据命令提示操作${plain}"
git clone https://github.com/btlanyan/nvjdc.git /root/nvjdc
docker pull 10529459/lanyannvjdc:1.4
apt install wget unzip -y
cd /root/nvjdc
mkdir -p  Config && cd Config
cat /root/nvjdc/Config/Config.json
read -p "请输入青龙服务器在web页面中显示的名称: " QLName && printf "\n"
read -p "请输入青龙OpenApi Client ID: " ClientID && printf "\n"
read -p "请输入青龙OpenApi Client Secret: " ClientSecret && printf "\n"
read -p "请输入青龙服务器的url地址（类似http://192.168.2.2:5700）: " QLurl && printf "\n"
read -p "请输入nvjdc面板希望使用的端口号: " jdcport && printf "\n"
cat >> Config.json << EOF
{
    ///最大支持几个网页
    "MaxTab": "20",
    //网站标题
    "Title": "Nvjdc",
    //回收时间分钟 不填默认3分钟
    "Closetime": "3",
    //网站公告
    "Announcement": "NolanHzy大佬写的工具，可以通过短信登录获取cookie，并自动同步到青龙面板那边，不再需要手动更新cookie",
    ///开启打印等待日志卡短信验证登陆 可开启 拿到日志群里回复 默认不要填写
    "Debug": "",
    ///自动滑块次数5次 5次后手动滑块 可设置为0默认手动滑块
    "AutoCaptchaCount": "5",
    ///XDD PLUS Url  http://IP地址:端口/api/login/smslogin
    "XDDurl": "",
    ///xddToken
    "XDDToken": "",
    ///多青龙配置
    "Config": [
        {
            //序号必须从1开始
            "QLkey": 1,
            //服务器名称
            "QLName": "青龙面板",
            //青龙url
            "QLurl": "http://qinglong:5700",
            //青龙2,9 OpenApi Client ID
            "QL_CLIENTID": "",
            //青龙2,9 OpenApi Client Secret
            "QL_SECRET": "",
            //青龙面包最大ck容量
            "QL_CAPACITY": 200,
            //消息推送二维码
            "QRurl": ""
        }
    ]
}

EOF
cd /root/nolanjdc && mkdir -p  .local-chromium/Linux-884014 && cd .local-chromium/Linux-884014
wget https://mirrors.huaweicloud.com/chromium-browser-snapshots/Linux_x64/884014/chrome-linux.zip && unzip chrome-linux.zip
rm  -f chrome-linux.zip
cd  /root/nvjdc


#判断机器是否安装docker
if test -z "$(which docker)"; then
echo -e "检测到系统未安装docker，开始安装docker"
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun > /dev/null 2>&1 
    curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi


#创建并启动nvjdc容器
cd /root/nvjdc
log_action_begin_msg "开始创建nvjdc容器"
docker run   --name nolanjdc -p ${portinfo}:80 -d  -v  "$(pwd)":/app \
-v /etc/localtime:/etc/localtime:ro \
-it --privileged=true  10529459/lanyannvjdc:1.4



echo -e "${green}安装完毕,面板访问地址：http://${baseip}:${jdcport}${plain}"
echo -e "${green}Faker集合仓库频道：${plain}${red}https://t.me/pandaqx${plain}"
}

update_nvjdc(){
  cd /root/nvjdc
portinfo=$(docker port nvjdc | head -1  | sed 's/ //g' | sed 's/80\/tcp->0.0.0.0://g')
baseip=$(curl -s ipip.ooo)  > /dev/null
docker rm -f nvjdc
docker pull nolanhzy/nvjdc:latest
docker run   --name nvjdc -p ${portinfo}:80 -d  -v  "$(pwd)"/app \
-v "$(pwd)"/.local-chromium:/app/.local-chromium  \
-it --privileged=true  nolanhzy/nvjdc:latest
echo -e "${green}nvjdc更新完毕，脚本自动退出。${plain}"
echo -e "${green}面板访问地址：http://${baseip}:${portinfo}${plain}"
exit 0
}

uninstall_nvjdc(){
docker rm -f nvjdc
docker rmi -f nolanhzy/nvjdc:0.4
rm -rf nvjdc
echo -e "${green}nvjdc面板已卸载，脚本自动退出。${plain}"
exit 0
}

menu() {
  echo -e "\
${green}0.${plain} 退出脚本
${green}1.${plain} 安装nvjdc
${green}2.${plain} 升级nvjdc
${green}3.${plain} 卸载nvjdc
"
get_system_info
echo -e "当前系统信息: ${Font_color_suffix}$opsy ${Green_font_prefix}$virtual${Font_color_suffix} $arch ${Green_font_prefix}$kern${Font_color_suffix}
"

  read -p "请输入数字 :" num
  case "$num" in
  0)
    quit
    ;;
  1)
    install_nvjdc
    ;;
  2)
    update_nvjdc
    ;;
  3)
    uninstall_nvjdc
    ;;    
  *)
  clear
    echo -e "${Error}:请输入正确数字 [0-2]"
    sleep 5s
    menu
    ;;
  esac
}

copyright

menu