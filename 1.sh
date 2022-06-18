#!/bin/bash
#author kissyouhunter

declare flag=0
clear
while [ "$flag" -eq 0 ]

# MaiARK 变量
MAIARK_DOCKER_IMG_NAME="kissyouhunter/maiark"
MAIARK_PATH=""
MAIARK_CONFIG_FOLDER=$(pwd)/MaiARK
N1_MAIARK_FOLDER=/mnt/mmcblk2p4/MarARK
MAIARK_CONTAINER_NAME=""
MAIARK_PORT="8082"

log() {
    echo -e "\n$1"
}
inp() {
    echo -e "\n$1"
}

opt() {
    echo -n -e "输入您的选择->"
}
cancelrun() {
    if [ $# -gt 0 ]; then
        echo -e " $1 "
    fi
    exit 1
}


TIME() {
[[ -z "$1" ]] && {
	echo -ne " "
} || {
     case $1 in
	r) export Color="\e[31;1m";;
	g) export Color="\e[32;1m";;
	b) export Color="\e[34;1m";;
	y) export Color="\e[33;1m";;
	z) export Color="\e[35;1m";;
	l) export Color="\e[36;1m";;
	w) export Color="\e[29;1m";;
      esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
      }
}





TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|************** MaiARK ****************|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、openwrt、群辉等请选择 1"
TIME w "(2) N1的EMMC上运行的openwrt请选择 2"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-2]: " input11
 case $input11 in 
 1)
  TIME y " >>>>>>>>>>>开始安装MaiARK (AMD64 CPU)"
  # 创建映射文件夹
  input_container_maiark1_config() {
  echo -n -e "请输入MaiARK配置文件保存的绝对路径（示例：/home/MaiARK)，回车默认为当前目录: "
  read maiark_path
  if [ -z "$maiark_path" ]; then
      MAIARK_PATH=$MAIARK_CONFIG_FOLDER
  elif [ -d "$maiark_path" ]; then
      MAIARK_PATH=$maiark_path
  else
      MAIARK_PATH=$maiark_path
  fi
  CONFIG_PATH=$MAIARK_PATH
  }
  input_container_maiark1_config

  # 输入容器名
  input_container_maiark1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：maiark]-> "
    read container_name
    if [ -z "$container_name" ]; then
        MAIARK_CONTAINER_NAME="maiark"
    else
        MAIARK_CONTAINER_NAME=$container_name
    fi
  }
  input_container_maiark1_name

  # 网络模式
  input_container_maiark1_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAIARK_PORT="8082"
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改MaiMRK端口[默认 8082]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_maiark_port
      if [ "$change_maiark_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read MAIARK_PORT
          echo $MAIARK_PORT
      else
          MAIARK_PORT="8082"
      fi
  fi
  }
  input_container_maiark1_network_config

  # 确认
  while true
  do
  	TIME y "MaiARK 配置文件路径：$CONFIG_PATH"
  	TIME y "Maiark 容器名：$MAIARK_CONTAINER_NAME"
    TIME y "Maiark 端口：$MAIARK_PORT"
    TIME r "确认下映射路径是否正确！！！"
  	read -r -p "以上信息是否正确？[Y/n] " input111
  	case $input111 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_maiark1_config
  			input_container_maiark1_name
            input_container_maiark1_network_config
            MAIARK_PORT="8082"
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装MaiARK"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker pull $MAIARK_DOCKER_IMG_NAME:$TAG
  docker run -d \
      -v $CONFIG_PATH:/MaiARK \
      --name $MAIARK_CONTAINER_NAME \
      --hostname $MAIARK_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      -p $MAIARK_PORT:8082 \
      $MAIARK_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------------------------------"
    TIME g "|                   MaiARK启动需要一点点时间，请耐心等待！                   |"
    sleep 10
    TIME g "|                          安装完成，自动退出脚本                            |"
    TIME g "|                          访问方式为 宿主机ip:$MAIARK_PORT                          |"
    TIME g "|              请先配置好映射文件夹下的arkconfig.json再重启容器              |"
    TIME r "|  桥接模式请不要修改config下的端口8082，host模式随意(前提是指定自己在干啥)  |"
    TIME r "|                 请看清映射的文件夹路径去找config文件                       |"
    TIME r "|   op用户出现“docker0: iptables: No chain/target/match by that name”错误    |"
    TIME r "|              输入命令“/etc/init.d/dockerd restart” 重启docker              |"
    TIME r "|                     再输入“docker start $MAIARK_CONTAINER_NAME” 启动容器                   |"
    TIME r "|       op用户出现容器正常启动，但web界面无法方法Turbo ACC 网络加速设置      |"
    TIME r "|进入“网络——Turbo ACC 网络加速设置” 开启或关闭“全锥型 NAT”就可正常访问web界面|"
    TIME g "------------------------------------------------------------------------------"
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装MaiARK到N1的/mnt/mmcblk2p4/"
  # 创建映射文件夹
  input_container_maiark3_config() {
  echo -n -e "请输入MaiARK存储的文件夹名称（如：MaiARK)，回车默认为 MaiARK: "
  read maiark_path
  if [ -z "$maiark_path" ]; then
      MAIARK_PATH=$N1_MAIARK_FOLDER
  elif [ -d "$maiark_path" ]; then
      MAIARK_PATH=/mnt/mmcblk2p4/$maiark_path
  else
      MAIARK_PATH=/mnt/mmcblk2p4/$maiark_path
  fi
  CONFIG_PATH=$MAIARK_PATH
  }
  input_container_maiark3_config
  
  # 输入容器名
  input_container_maiark3_name() {
    echo -n -e "请输入将要创建的容器名[默认为：maiark]-> "
    read container_name
    if [ -z "$container_name" ]; then
        MAIARK_CONTAINER_NAME="maiark"
    else
        MAIARK_CONTAINER_NAME=$container_name
    fi
  }
  input_container_maiark3_name

  # 网络模式
  input_container_maiark3_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAIARK_PORT="8082"
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改MaiMRK端口[默认 8082]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_maiark_port
      if [ "$change_maiark_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read MAIARK_PORT
      else
          MAIARK_PORT="8082"
      fi
  fi
  }
  input_container_maiark3_network_config


  # 确认
  while true
  do
  	TIME y "MaiARK 配置文件路径：$CONFIG_PATH"
  	TIME y "MaiARK 容器名：$MAIARK_CONTAINER_NAME"
    TIME y "Maiark 端口：$MAIARK_PORT"
    TIME r "确认下映射路径是否正确！！！"
  	read -r -p "以上信息是否正确？[Y/n] " input113
  	case $input113 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_maiark3_config
  			input_container_maiark3_name
            input_container_maiark3_network_config
            MAIARK_PORT="8082"
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装MaiARK"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker pull $MAIARK_DOCKER_IMG_NAME:$TAG
  docker run -dit \
      -t \
      -v $CONFIG_PATH:/MaiARK \
      --name $MAIARK_CONTAINER_NAME \
      --hostname $MAIARK_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      -p $MAIARK_PORT:8082 \
      $MAIARK_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------------------------------"
    TIME g "|                   MaiARK启动需要一点点时间，请耐心等待！                   |"
    sleep 10
    TIME g "|                          安装完成，自动退出脚本                            |"
    TIME g "|                          访问方式为 宿主机ip:$MAIARK_PORT                          |"
    TIME g "|              请先配置好映射文件夹下的arkconfig.json再重启容器              |"
    TIME r "|  桥接模式请不要修改config下的端口8082，host模式随意(前提是指定自己在干啥)  |"
    TIME r "|                 请看清映射的文件夹路径去找config文件                       |"
    TIME r "|   op用户出现“docker0: iptables: No chain/target/match by that name”错误    |"
    TIME r "|              输入命令“/etc/init.d/dockerd restart” 重启docker              |"
    TIME r "|                     再输入“docker start $MAIARK_CONTAINER_NAME” 启动容器                   |"
    TIME r "|       op用户出现容器正常启动，但web界面无法方法Turbo ACC 网络加速设置      |"
    TIME r "|进入“网络——Turbo ACC 网络加速设置” 开启或关闭“全锥型 NAT”就可正常访问web界面|"
    TIME g "------------------------------------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
*) TIME r "----------------------------------"
 TIME r "|          Warning!!!            |"
 TIME r "|       请输入正确的选项!        |"
 TIME r  "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
;;
esac
done