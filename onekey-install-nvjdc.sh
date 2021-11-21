#/usr/bin/env bash
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1
clear

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

copyright(){
    clear
echo -e "
—————————————————————————————————————————————————————————————
        Nvjdc自助面板一键安装脚本                    
 ${green}                
        
  
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
cd .. && cd ..
cat /root/nvjdc/Config/Config.json
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



#创建并启动nvjdc容器
cd /root/nvjdc
log_action_begin_msg "开始创建nvjdc容器"
docker run   --name nvjdc -p 5800:80 -d  -v  "$(pwd)":/app \
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
