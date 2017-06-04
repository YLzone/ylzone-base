#!/bin/bash
#=======================================================================#
#                                                                       #
#         文件名:    tomcat_instal.sh                                   #
#         描述信息:  tomcat自动部署脚本                                 #
#         当前版本:  2.0                                                #
#         创建时间:  2017年6月9日                                       #
#         功能介绍:  自动化部署                                         #
#                                                                       #
#========================================================================

#=======================================================================#
#    函数: logger
#    参数: <$1> 日志内容
#    说明: 格式化记录日志
#=======================================================================#
logger() {
    echo "[$(date +%F_%T)] - [${FUNCNAME[1]}] - $1"
}

#=======================================================================#
#    说明: 依赖程序检测
#=======================================================================#
which git  &> /dev/null || { logger "所需程序 git 不存在,请安装后再试"; exit 1; }
which wget &> /dev/null || { logger "所需程序 wget 不存在,请安装后再试"; exit 1; }

#=======================================================================#
#    说明: 输入检测部分
#=======================================================================#
SCRIPT_PWD=$(dirname $(dirname $(readlink -f $0)))
TC_USER=
TC_HOME=
TC_BASE=
TC_PACKET="/tmp/apache-tomcat-7.0.72.tar.gz"
TC_URL="http://apache.fayea.com/tomcat/tomcat-7/v7.0.78/bin/apache-tomcat-7.0.72.tar.gz"

_TC_USER_DEFAULT="tomcat"
_TC_HOME_DEFAULT="/opt/tomcat7"
_TC_BASE_DEFAULT="/data/tomcat"
read -p "输入运行用户[${_TC_USER_DEFAULT}]: " TC_USER; [ -z "$TC_USER" ] && TC_USER=${_TC_USER_DEFAULT}
read -p "输入安装目录[${_TC_HOME_DEFAULT}]: " TC_HOME; [ -z "$TC_HOME" ] && TC_HOME=${_TC_HOME_DEFAULT}
read -p "输入数据目录[${_TC_BASE_DEFAULT}]: " TC_BASE; [ -z "$TC_BASE" ] && TC_BASE=${_TC_BASE_DEFAULT}

cat <<EOF
*******************************************
    运行用户      : ${TC_USER}
    安装目录      : ${TC_HOME}
    数据目录      : ${TC_BASE}
*******************************************
EOF

read -p "请核对如上信息是否正确 [y/n]: " result; [ -z "$result" ] && { logger "输入不能为空"; exit 1; }
[ ${result} != "y" ] && exit 1
INSTALL_BASE=$(dirname ${TC_HOME})

#=======================================================================#
#    说明: 进入安装部分
#=======================================================================#
### 1.解决依赖 ###

# 检测下载安装包 
if [ ! -e ${TC_PACKET} ]; then
    logger "<解决依赖> 安装包不存在,准备下载 zookeeper-3.4.9.tar.gz"
    wget ${TC_URL} -P /tmp || { logger "<解决依赖> 下载软件包失败"; exit 1; }
else
    logger "<解决依赖> 安装包 ${TC_PACKET} 存在继续安装"
fi

# 检测加载base包
git clone git@try.gogs.io:yangli886/ylzone-base.git /tmp/ylzone-base
mkdir -v ${TC_BASE}
mv /tmp/ylzone-base/tomcat7-base /data/tomcat/.catalina-base

# 检测添加运行用户
id ${TC_USER} &>/dev/null
if [ $? = 0 ]; then
    logger "<解决依赖> 用户 ${TC_USER} 存在无需创建"
else
    useradd -M -d ${TC_BASE} -u 8080 tomcat && logger "<解决依赖> 创建用户 ${TC_USER} 成功!" \
                                            || { logger "<解决依赖> 创建用户 ${TC_USER} 失败"; exit 1; }
fi

### 2.安装程序 ###

# 解压程序包
tar xf ${TC_PACKET} -C ${INSTALL_BASE} && logger "<安装程序> ${TC_PACKET} ==> ${INSTALL_BASE} 解压成功!" \
                                       || logger "<安装程序> ${TC_PACKET} ==> ${INSTALL_BASE} 解压失败"
result=$(ln -sv ${INSTALL_BASE}/apache-tomcat-7.0.72/ ${TC_HOME} 2>&1); logger "<安装程序> ${result}"

# 整理安装目录
rm -f  ${TC_HOME}/{LICENSE,NOTICE,RELEASE-NOTES,RUNNING.txt} &&
rm -f  ${TC_HOME}/bin/*.bat                                  &&
rm -rf ${TC_HOME}/{logs,temp,webapps,work}                   &&
mv ${TC_HOME}/{conf,conf.default}                            && logger "<安装程序> 整理安装目录完成"

# 创建所需目录
# data  : 共享数据目录,负载均衡时节点之间共享数据
# local : 本地数据目录,负载均衡时节点本地的数据
result=$(mkdir -v ${TC_BASE}                      2>&1); logger "<安装程序> ${result}"
result=$(mkdir -v ${TC_BASE}/.catalina-base       2>&1); logger "<安装程序> ${result}"
result=$(mkdir -v ${TC_BASE}/.catalina-base/logs  2>&1); logger "<安装程序> ${result}"
result=$(mkdir -v ${TC_BASE}/.catalina-base/work  2>&1); logger "<安装程序> ${result}"
result=$(mkdir -v ${TC_BASE}/.catalina-base/temp  2>&1); logger "<安装程序> ${result}"
result=$(mkdir -v ${TC_BASE}/.catalina-base/data  2>&1); logger "<安装程序> ${result}"
result=$(mkdir -v ${TC_BASE}/.catalina-base/local 2>&1); logger "<安装程序> ${result}"
result=$(ln -sv ${TC_BASE}/.catalina-base/webapps/ ${TC_BASE}/webapps 2>&1); logger "<安装程序> ${result}"
result=$(ln -sv ${TC_BASE}/.catalina-base/logs/    ${TC_BASE}/logs    2>&1); logger "<安装程序> ${result}"
result=$(ln -sv ${TC_BASE}/.catalina-base/data/    ${TC_BASE}/data    2>&1); logger "<安装程序> ${result}"
result=$(ln -sv ${TC_BASE}/.catalina-base/local/   ${TC_BASE}/local   2>&1); logger "<安装程序> ${result}"

# 修改文件权限
chown -R root:root ${TC_HOME}                     && logger "<安装程序> 修改安装目录权限 root:root"
chown -R ${TC_USER}:${TC_USER} ${TC_BASE}         && logger "<安装程序> 修改数据目录权限 ${TC_USER}:${TC_USER}"
chown -R root:root ${TC_BASE}/.catalina-base/conf && logger "<安装程序> 修改配置目录权限 root:root"

