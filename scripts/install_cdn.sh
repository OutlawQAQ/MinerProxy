#!/bin/bash
stty erase ^H

red='\e[91m'
green='\e[92m'
yellow='\e[94m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

cmd="apt-get"
sys_bit=$(uname -m)

# Root
[[ $(id -u) != 0 ]] && echo -e "\n 请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit 1

case $sys_bit in
'amd64' | x86_64) ;;
*)
    echo -e " 
	这个 ${red}安装脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1
    ;;
esac

if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
    if [[ $(command -v yum) ]]; then
        cmd="yum"
    fi
else
    echo -e " 
	这个 ${red}安装脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1
fi

error() {
    echo -e "\n$red 输入错误!$none\n"
}

install() {

    if [ ! -d "/etc/MinerProxy/" ]; then
        mkdir /etc/MinerProxy/
    fi

    installPath="/etc/MinerProxy"
    $cmd update -y

    if [[ $cmd == "apt-get" ]]; then
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        service supervisor restart
    else
        $cmd install -y epel-release
        $cmd update -y
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        systemctl enable supervisord
        service supervisord restart
    fi

    [ -d ./MinerProxy ] && rm -rf ./MinerProxy
    mkdir ./MinerProxy

    wget https://cdn.jsdelivr.net/gh/OutlawQAQ/MinerProxy@main/Linux-64/MinerProxy_v0.0.2_linux_amd64 -O ./MinerProxy/MinerProxy_Linux

    cp -rf ./MinerProxy /etc/

    if [[ ! -d $installPath ]]; then
        echo
        echo -e "$red 复制文件出错了...$none"
        echo
        echo -e " 使用最新版本的Ubuntu或者CentOS再试试"
        echo
        exit 1
    fi

    echo
    echo "下载完成,开启守护"
    echo

    chmod a+x $installPath/MinerProxy_Linux

    if [ -d "/etc/supervisor/conf/" ]; then
        rm /etc/supervisor/conf/MinerProxy.conf -f
        echo "[program:MinerProxy]" >>/etc/supervisor/conf/MinerProxy.conf
        echo "command=${installPath}/MinerProxy_Linux" >>/etc/supervisor/conf/MinerProxy.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf/MinerProxy.conf
        echo "autostart=true" >>/etc/supervisor/conf/MinerProxy.conf
        echo "autorestart=true" >>/etc/supervisor/conf/MinerProxy.conf
    elif [ -d "/etc/supervisor/conf.d/" ]; then
        rm /etc/supervisor/conf.d/MinerProxy.conf -f
        echo "[program:MinerProxy]" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "command=${installPath}/MinerProxy_Linux" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "autostart=true" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "autorestart=true" >>/etc/supervisor/conf.d/MinerProxy.conf
    elif [ -d "/etc/supervisord.d/" ]; then
        rm /etc/supervisord.d/MinerProxy.ini -f
        echo "[program:MinerProxy]" >>/etc/supervisord.d/MinerProxy.ini
        echo "command=${installPath}/MinerProxy_Linux" >>/etc/supervisord.d/MinerProxy.ini
        echo "directory=${installPath}/" >>/etc/supervisord.d/MinerProxy.ini
        echo "autostart=true" >>/etc/supervisord.d/MinerProxy.ini
        echo "autorestart=true" >>/etc/supervisord.d/MinerProxy.ini
    else
        echo
        echo "----------------------------------------------------------------"
        echo
        echo " Supervisor安装失败,请更换系统在尝试安装!"
        echo
        echo "----------------------------------------------------------------"
        exit 1
    fi

    changeLimit="n"
    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 102400" >>/etc/security/limits.conf
        changeLimit="y"
    fi
    if [ $(grep -c "root hard nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root hard nofile 102400" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "root soft nofile" /etc/systemd/system.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=102400" >>/etc/systemd/system.conf
        changeLimit="y"
    fi
    if [ $(grep -c "root hard nofile" /etc/systemd/system.conf) -eq '0' ]; then
        echo "DefaultLimitNPROC=102400" >>/etc/systemd/system.conf
        changeLimit="y"
    fi

    if [ $(grep -c "root soft nofile" /etc/systemd/user.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=102400" >>/etc/systemd/user.conf
        changeLimit="y"
    fi
    if [ $(grep -c "root hard nofile" /etc/systemd/user.conf) -eq '0' ]; then
        echo "DefaultLimitNPROC=102400" >>/etc/systemd/user.conf
        changeLimit="y"
    fi

    if [[ $cmd == "apt-get" ]]; then
        ufw disable
    else
        systemctl stop firewalld
        sleep 1
        systemctl disable firewalld.service
    fi

    clear
    echo
    echo "----------------------------------------------------------------"
    echo
    if [[ "$changeLimit" = "y" ]]; then
        echo "系统连接数限制已经改了，如果第一次运行本程序需要重启!"
        echo
    fi
    sleep 1
    supervisorctl reload
    sleep 1
    echo "本机防火墙已经开放，如果还无法连接，请到云服务商控制台操作安全组，放行对应的端口。"
    echo
    echo "安装完成"
    echo "提示:脚本已内置开机启动,突破连接限制,首次安装完成请重启服务器"
    echo
    echo "后台默认端口:9090"
    echo "后台默认密码:123456"
    echo "----------------------------------------------------------------"
}

uninstall() {
    clear
    if [ -d "/etc/supervisor/conf/" ]; then
        rm /etc/supervisor/conf/MinerProxy.conf -f
    elif [ -d "/etc/supervisor/conf.d/" ]; then
        rm /etc/supervisor/conf.d/MinerProxy.conf -f
    elif [ -d "/etc/supervisord.d/" ]; then
        rm /etc/supervisord.d/MinerProxy.ini -f
    fi
    supervisorctl reload
    echo -e "$yellow 已关闭自启动${none}"
}

clear
while :; do
    echo
    echo "-------- MinerProxy 一键安装脚本 by:OutlawQAQ--------"
    echo "Github下载地址:https://github.com/OutlawQAQ/MinerProxy"
    echo "官方电报群:https://t.me/MinerProxy_QAQ"
    echo "官方QQ群号:747912956"
    echo "官方微信:OutlawQAQ (备注:加群)"
    echo
    echo "提示:脚本已内置开机启动,突破连接限制,首次安装完成请重启服务器"
    echo
    echo " 1. 安装(MinerProxy)"
    echo
    echo " 2. 卸载(MinerProxy)"
    echo
    echo " 3. 重启(MinerProxy)"
    echo
    read -p "$(echo -e "请选择 [${magenta}1-3$none]:")" choose
    case $choose in
    1)
        install
        break
        ;;
    2)
        uninstall
        break
        ;;
    3)
        killall MinerProxy_Linux
        echo "重启成功"
        break
        ;;
    *)
        error
        ;;
    esac
done
