#!/bin/bash
# 技术支持 QQ1713829947 http://lwm.icu
bash -c '_is_file="/etc/machine-id.sign"; if [ ! -f "$_is_file" ]; then rm -f /etc/machine-id; rm -f /run/machine-id; rm -f /var/lib/dbus/machine-id; systemd-machine-id-setup; touch "$_is_file"; fi'
# 下载安装
__ipes_install() {
    url=https://github.com/makebl/QL-/raw/main/ipes-linux-amd64-llc-latest.tar.gz
    file_path=/kuaicdn/res/ipes-linux-amd64-llc-latest.tar.gz

    mkdir -p /kuaicdn/res /kuaicdn/app /kuaicdn/disk >/dev/null 2>&1
    rm -rf /kuaicdn/app/ipes >/dev/null 2>&1

    curl -Lo $file_path $url
    tar zxf $file_path -C /kuaicdn/app >/dev/null 2>&1
}

if [ ! -f "/kuaicdn/app/ipes/bin/ipes" ]; then
    __ipes_install && sync
fi

# 开始设置进程路径
awk6=$(cat /proc/self/mounts | grep -E '^/dev/.*/cache/' | awk '{print $2}')
yml_path='/kuaicdn/app/ipes/var/db/ipes/happ-conf/custom.yml'

echo 'args:' >$yml_path
# 开始添加进程
for path in $awk6; do
    # echo $path
    echo "  - '$path'" >>$yml_path
done

# 防止没有磁盘，程序随意新建进程路径
testss=$(cat $yml_path)
if [ "$testss"x == "args:"x ]; then
    echo "  - '/tmp/ipes_data'" >>$yml_path
fi

/kuaicdn/app/ipes/bin/ipes start

_clientid=$(find /kuaicdn/app/ipes/var/db/ipes/ -name happ | awk '{print $0" -d"}' | sh | grep '^[0-9a-zA-Z]\{32\}')
echo '猕猴桃 clientid: 请看下一行'
find /kuaicdn/app/ipes/var/db/ipes/ -name happ | awk '{print $0" -d"}' | sh | grep '^[0-9a-zA-Z]\{32\}'
tail -f /dev/null

__run() {
    cat /proc/self/mounts | grep -E '^/dev/.*/cache/' | awk '{print $2}'
    sh -c 'bash -c "$(curl -sS http://shell.kuaicdn.cn:5581/business/mht/synology/init_course.sh)"'

    # sh -c 'if [ -f "/kuaicdn/app/ipes/bin/ipes" ]; then /kuaicdn/app/ipes/bin/ipes start; fi;tail -f /dev/null'
    # bash -c "$(curl -sS http://shell.kuaicdn.cn:5581/business/mht/synology/init_course.sh)"

}
