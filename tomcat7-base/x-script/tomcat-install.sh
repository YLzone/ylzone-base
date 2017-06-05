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
    message=$1
    arg=${2:-"NULL"}
    [ $arg == "-error" ] && echo -e "[$(date "+%F %T")] - [${FUNCNAME[1]}] - [\033[1;31mERRO\033[m] <${_MSG_PERFIX}> $1" \
                         || echo -e "[$(date "+%F %T")] - [${FUNCNAME[1]}] - [\033[1;32mINFO\033[m] <${_MSG_PERFIX}> $1"
}

#=======================================================================#
#    说明: 公共变量
#=======================================================================#
SCRIPT_PWD=$(dirname $(dirname $(readlink -f $0)))
TC_USER=
TC_HOME=
TC_BASE=
TC_PACKET_VERSION="apache-tomcat-7.0.78"
TC_PACKET_PATH="/tmp/${TC_PACKET_VERSION}.tar.gz"
TC_URL="http://apache.fayea.com/tomcat/tomcat-7/v7.0.78/bin/${TC_PACKET_VERSION}.tar.gz"
TC_YLZONE_BASE=/tmp/ylzone-base/tomcat7-base


#=======================================================================#
#    说明: 检测环境
#=======================================================================#
_MSG_PERFIX="检测环境"
# 1.检测所需程序
which git  &> /dev/null || { logger "所需程序 git 不存在,请安装后再试"  -error; exit 1; }
which wget &> /dev/null || { logger "所需程序 wget 不存在,请安装后再试" -error; exit 1; }

# 2.检测程序包
if [ ! -e ${TC_PACKET_PATH} ]; then
    logger "安装包不存在,准备下载 ${TC_PACKET_VERSION}.tar.gz"
    wget ${TC_URL} -P /tmp || { logger " 下载软件包失败" -error; exit 1; }
else
    logger "安装包 ${TC_PACKET_PATH} 存在继续安装"
fi

# 3.检测BASE包
if [ ! -e ${TC_YLZONE_BASE} ]; then
    [ -e /tmp/ylzone-base ] && rm -rf /tmp/ylzone-base
    logger "BASE包不存在,准备下载 ylzone-base"
    git clone https://github.com/YLzone/ylzone-base.git /tmp/ylzone-base
else
    logger "BASE包存在继续安装"
fi

logger "\033[1m---------------------------------------------------\033[m"
logger "检测环境满足部署需求可正常进行！"
logger "\033[1m---------------------------------------------------\033[m"

#=======================================================================#
#    说明: 检测输入
#=======================================================================#
_MSG_PERFIX="检测输入"
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

read -p "请核对如上信息是否正确 [y/n]: " result; [ -z "$result" ] && { logger "输入不能为空" -error; exit 1; }
[ ${result} != "y" ] && exit 1
INSTALL_BASE=$(dirname ${TC_HOME})

#=======================================================================#
#    说明: 安装程序
#=======================================================================#
_MSG_PERFIX="安装程序"
### 1.解决依赖 ###

# 检测添加运行用户
id ${TC_USER} &>/dev/null
if [ $? = 0 ]; then
    logger "用户 ${TC_USER} 存在无需创建"
else
    useradd -u 8080 tomcat &&   logger "创建用户 ${TC_USER} 成功!"  \
                           || { logger "创建用户 ${TC_USER} 失败" -error; exit 1; }
fi

### 2.安装程序 ###

# 解压程序包
tar xf ${TC_PACKET_PATH} -C ${INSTALL_BASE} &&   logger "${TC_PACKET_PATH} ==> ${INSTALL_BASE} 解压成功!" \
                                            || { logger "${TC_PACKET_PATH} ==> ${INSTALL_BASE} 解压失败" -error; exit 1; }

result=$(ln -sv ${INSTALL_BASE}/${TC_PACKET_VERSION}/ ${TC_HOME} 2>&1) &&   logger "${result}" \
                                                                       || { logger "${result}" -error; exit 1; }

# 整理安装目录
rm -f  ${TC_HOME}/{LICENSE,NOTICE,RELEASE-NOTES,RUNNING.txt} || { logger "安装目录清理失败" -error; exit 1; }
rm -f  ${TC_HOME}/bin/*.bat                                  || { logger "安装目录清理失败" -error; exit 1; }
rm -rf ${TC_HOME}/{logs,temp,webapps,work}                   || { logger "安装目录清理失败" -error; exit 1; }
mv ${TC_HOME}/{conf,conf.default}                            &&   logger "整理安装目录完成" \
                                                             || { logger "安装目录清理失败" -error; exit 1; }


# 创建所需目录
# data  : 共享数据目录,负载均衡时节点之间共享数据
# local : 本地数据目录,负载均衡时节点本地的数据
result=$(mkdir -v ${TC_BASE}                      2>&1)                         && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(mv    -v /tmp/ylzone-base/tomcat7-base ${TC_BASE}/.catalina-base 2>&1) && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(mkdir -v ${TC_BASE}/.catalina-base/run   2>&1)                         && logger "${result}" || { logger "${result}" -error; exit 1; } 
result=$(mkdir -v ${TC_BASE}/.catalina-base/logs  2>&1)                         && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(mkdir -v ${TC_BASE}/.catalina-base/work  2>&1)                         && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(mkdir -v ${TC_BASE}/.catalina-base/temp  2>&1)                         && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(mkdir -v ${TC_BASE}/.catalina-base/data  2>&1)                         && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(mkdir -v ${TC_BASE}/.catalina-base/local 2>&1)                         && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(ln -sv .catalina-base/webapps/ ${TC_BASE}/webapps 2>&1)                && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(ln -sv .catalina-base/logs/    ${TC_BASE}/logs    2>&1)                && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(ln -sv .catalina-base/data/    ${TC_BASE}/data    2>&1)                && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(ln -sv .catalina-base/local/   ${TC_BASE}/local   2>&1)                && logger "${result}" || { logger "${result}" -error; exit 1; }
result=$(ln -sv .catalina-base/x-script/tomcat.sh   ${TC_BASE}/tomcat   2>&1)   && logger "${result}" || { logger "${result}" -error; exit 1; }

# 修改文件权限
chown -R root:root ${TC_HOME}                     && logger "修改安装目录权限 root:root"
chown -R ${TC_USER}:${TC_USER} ${TC_BASE}         && logger "修改数据目录权限 ${TC_USER}:${TC_USER}"
chown -R root:root ${TC_BASE}/.catalina-base/conf && logger "修改配置目录权限 root:root"
