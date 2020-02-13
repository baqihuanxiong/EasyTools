#!/bin/bash
# Version: 0.0.1
# Author: baqihuanxiong
# Date: 2020.2.9

set -e
set -x

if [ "$(id -u)" -ne 0 ]; then
    echo "Must run as root!"
    exit 1
fi

workdir=$(cd $(dirname $0); pwd)
cd $workdir

cloud::install_docker() {
    if [ -z $(which docker) ]; then
        curl -sSL https://get.docker.com | sh
    fi
    systemctl enable docker && systemctl start docker
}

cloud::install_docker_compose() {
    if [ -z $(which docker-compose) ]; then
        curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}

cloud::install_templete_custom() {
    cd custom
    mkdir -p /etc/v2ray
    cp v2ray/*.json /etc/v2ray
    mkdir -p /etc/nginx
    cp nginx/*.conf /etc/nginx
    docker-compose up -d
}

cloud::install_templete_nginx() {
    cd custom
    mkdir -p /etc/v2ray
    cp v2ray/*.json /etc/v2ray
    docker-compose up -d
}

cloud::tear_down() {
    set +e
    cd $1
    docker-compose down
    set -e
}

cloud::bbr_on() {
    require="4.9.0"
    kernal=$(uname -r)
    if test "$(echo "${kernal}" "${require}" | tr " " "\n" | sort -rV | head -n 1)" != "${kernal}"; then 
        echo "BBR only support kernel $require or above."
        exit 1
    fi
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p
    echo "BBR on, require reboot."
}

cloud::bbr_off() {
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    sysctl -p
    echo "BBR off, require reboot."
}

main() {
    case $1 in
    "up" )
        if [ -z $2 ]; then
            echo "usage: $0 up {template}"
            exit 1
        fi
        if echo $(ls -l | awk '/^d/ {print $NF}') | grep -v -w $2 &>/dev/null; then
            echo "templete $2 not found"
            exit 1
        fi
        cloud::install_docker
        cloud::install_docker_compose
        cloud::install_templete_$2
        ;;
    "down" )
        if [ -z $2 ]; then
            echo "usage: $0 down {template}"
            exit 1
        fi
        if echo $(ls -l | awk '/^d/ {print $NF}') | grep -v -w $2 &>/dev/null; then
            echo "templete $2 not found"
            exit 1
        fi
        cloud::tear_down $2
        ;;
    "bbr" )
        case $2 in
        "on" )
            cloud::bbr_on
            ;;
        "off" )
            cloud::bbr_off
            ;;
        * )
            echo "usage: $0 bbr on | off"
            ;;
        esac
        ;;
    * )
        echo "usage: $0 up | down | bbr"
        ;;
    esac
}

main "$@"