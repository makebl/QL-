#!/usr/bin/env bash
# 
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
      esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
      }
}

[[ ! "$USER" == "root" ]] && {
	clear
	echo
	TIME y "警告：请使用root用户操作!~~"
	echo
	sleep 2
	exit 1
}

if [[ -z "$(ls -A "/etc/openwrt_release" 2>/dev/null)" ]]; then
	sudo -E apt-get -qq update
	apt install -y sudo curl dpkg wget
fi

if [[ -n "$(ls -A "/etc/openwrt_release" 2>/dev/null)" ]]; then
	if [[ `docker version | grep -c "version"` -eq '0' ]]; then
		echo
		TIME y "没检测到docker，请先安装docker"
		echo
		sleep 3
		exit 1
	fi
else
	if [[ `docker version | grep -c "version"` -eq '0' ]]; then
		echo
		TIME y "没检测到docker，正在安装docker，请稍后..."
		echo
		wget -O docker.sh https://ghproxy.com/https://raw.githubusercontent.com/281677160/ql/main/docker.sh && bash docker.sh
		if [[ $? -ne 0 ]];then
			curl -fsSL https://cdn.jsdelivr.net/gh/281677160/ql@main/docker.sh && bash docker.sh
		fi
		
	fi
fi
if [[ -n "$(ls -A "/etc/openwrt_release" 2>/dev/null)" ]]; then
	if [[ `docker version | grep -c "version"` -eq '0' ]]; then
		echo
		TIME y "没检测到docker，请先安装docker"
		echo
		sleep 3
		exit 1
	fi
else
	if [[ `docker version | grep -c "version"` -eq '0' ]]; then
		echo
		TIME y "没检测到docker，请先安装docker"
		echo
		sleep 3
		exit 1
	fi
fi
if [[ `docker ps -a | grep -c "whyour"` -ge '1' ]]; then
	echo
	TIME g "检测到已有青龙面板，需要删除面板才能继续..."
	echo
	TIME y "如果要继续的话，请注意备份你原来的配置文件!"
	echo
	read -p " [输入[ N/n ]退出安装，输入[ Y/y ]回车继续]： " SCQL
	case $SCQL in
		[Yy])
			echo
			TIME y "正在停止您以前的青龙然后删除，请稍后...!"
			echo
			docker=$(docker ps|grep whyour) && dockerid=$(awk '{print $(1)}' <<<${docker})
			images=$(docker images|grep whyour) && imagesid=$(awk '{print $(3)}' <<<${images})
			docker stop -t=5 "${dockerid}"
			docker rm "${dockerid}"
			docker rmi "${imagesid}"
		;;
		[Nn])
			TIME r "退出安装程序!"
			sleep 2
			exit 1
		;;
	esac
fi

rm -rf /opt/ql
rm -rf /root/ql
sleep 3
echo

if [[ -n "$(ls -A "/etc/openwrt_release" 2>/dev/null)" ]]; then
echo
TIME g "正在安装青龙面板，请稍后..."
echo
docker run -dit \
  -v $PWD/ql/config:/ql/config \
  -v $PWD/ql/log:/ql/log \
  -v $PWD/ql/db:/ql/db \
  -v $PWD/ql/scripts:/ql/scripts \
  -v $PWD/ql/jbot:/ql/jbot \
  -v $PWD/ql/raw:/ql/raw \
  -v $PWD/ql/repo:/ql/repo \
  --net host \
  --name qinglong \
  --hostname qinglong \
  --restart always \
  whyour/qinglong:latest
else
TIME g "正在安装青龙面板，请稍后..."
echo
docker run -dit \
   -v /opt/ql/config:/ql/config \
   -v /opt/ql/log:/ql/log \
   -v /opt/ql/db:/ql/db \
   -v /opt/ql/scripts:/ql/scripts \
   -v /opt/ql/jbot:/ql/jbot \
   -v /opt/ql/raw:/ql/raw \
   -v /opt/ql/repo:/ql/repo \
   -p 5700:5700 \
   --name qinglong \
   --hostname qinglong \
   --restart always \
   whyour/qinglong:latest
fi

if [[ `docker ps -a | grep -c "whyour"` -ge '1' ]]; then
	docker restart qinglong
	sleep 13
	echo
	TIME z "青龙面板安装完成"
	echo
	TIME g "请使用 IP:5700 在浏览器登录控制面板，然后在环境变量里添加好WSKEY或者PT_KEY"
	echo
	TIME y "您也可以不添加WSKEY或者PT_KEY，但是一定要登录管理面"
	echo
	TIME g "重要提示：重要，一定要登录管理面板之后再执行下一步操作！！！"
	echo
	TIME y "输入 N 回车退出程序，或者进入过管理页面后输入 Y 回车继续安装脚本"
	echo
	read -p " [ N/n ]退出程序，[ Y/y ]回车继续安装脚本： " MENU
	case $MENU in
		[Yy])
			echo
			TIME y "开始安装脚本，请耐心等待..."
			echo
			docker exec -it qinglong bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/281677160/ql/main/feverrun.sh)"
			if [[ $? -ne 0 ]];then
				docker exec -it qinglong bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/281677160/ql@main/feverrun.sh)"
			fi
			rm -fr ql.sh
		;;
		[Nn])
			TIME r "退出安装程序!"
			sleep 2
			exit 1
		;;
	esac
else
	TIME y "青龙面板安装失败！"
	sleep 2
	exit 1
fi
echo
echo
if [[ `docker ps -a | grep -c "whyour"` -ge '1' ]]; then
	TIME l "安装依赖，依赖必须安装，要不然脚本不运行"
	echo
	TIME y "但是用国内的网络安装比较慢，请尽量使用翻墙网络"
	echo
	TIME g "没翻墙条件的话，安装依赖太慢就换时间安装，我测试过不同时段有不同效果"
	echo
	TIME y "依赖安装时看到显示ERR!错误提示的，不用管，只要依赖能从头到尾的下载运行完毕就好了"
	echo
	TIME g "如果安装太慢，而想换时间安装的话，按键盘的 Ctrl+C 退出就行了，到时候可以使用我的一键独立安装依赖脚本来安装"
	echo
	sleep 15
	docker exec -it qinglong bash -c  "$(curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/281677160/ql/main/npm.sh)"
	if [[ $? -ne 0 ]];then
		docker exec -it qinglong bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/281677160/ql@main/npm.sh)"
	fi
fi

exit 0
