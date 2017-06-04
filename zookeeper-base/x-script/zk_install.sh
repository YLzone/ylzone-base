#!/bin/bash
#=======================================================================#
#                                                                       #
#         文件名:    zk_instal.sh                                       #
#         描述信息:  zookeeper自动部署脚本                              #
#         当前版本:  1.1                                                #
#         创建时间:  2017年6月7日                                       #
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


_BASE_DIR=$(dirname $(dirname $(readlink -f $0)))
read -p "输入程序根目录(INSTALL_BASE) [/opt]: "        INSTALL_BASE
read -p "输入数据目录(ZOO_BASE) [${_BASE_DIR}]: "      ZOO_BASE
read -p "输入部署节点列表,格式为 host1:host2:host3 : " ZOO_HOST_LIST
read -p "输入节点ID(myid): "                           ZOO_MYID

INSTALL_BASE=${INSTALL_BASE:-/opt}
ZOO_BASE=${ZOO_BASE:-${_BASE_DIR}}
ZOO_HOST_LIST=${ZOO_HOST_LIST:-NULL}
ZOO_MYID=${ZOO_MYID:-NULL}


[ $ZOO_HOST_LIST = "NULL" ] && { logger "主机列表(ZOO_HOST_LIST)不能为空请重新输入"; exit 1; }
[ $ZOO_MYID = "NULL" ]      && { logger "主机编号(ZOO_MYID)不能为空请重新输入"; exit 1; }

ZOO_HOST_LIST=$(echo ${ZOO_HOST_LIST} | tr ":" " ")
ZOO_PACKET=/tmp/zookeeper-3.4.9.tar.gz
ZOO_USER=zookep
ZOO_BASE=${ZOO_BASE}
ZOO_CONF_DIR=${ZOO_BASE}/conf
ZOO_DATA_DIR=${ZOO_BASE}/data

cat <<EOF
*******************************************
    运行用户      : ${ZOO_USER}
    节点编号(myid): ${ZOO_MYID}
    节点列表      : ${ZOO_HOST_LIST}
    安装目录      : ${INSTALL_BASE}
    基础目录      : ${ZOO_BASE}
*******************************************
EOF

read -p "请核对如上信息是否正确 [y/n]: " result && result=${result:-NULL}
[ ${result} != "y" ] && exit 1


# 解决依赖
if [ ! -e ${ZOO_PACKET} ]; then
    logger "<解决依赖> 安装包不存在,准备下载 zookeeper-3.4.9.tar.gz"
    wget http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.9/zookeeper-3.4.9.tar.gz -P /tmp ||
        logger "<解决依赖> wget命令不存在或下载失败"
else
    logger "<解决依赖> 安装包 ${ZOO_PACKET} 存在继续安装"
fi

id zookep &>/dev/null
if [ $? = 0 ]; then
    logger "<解决依赖> 用户 zookep 存在无需创建"
else
    useradd -M -s /sbin/nologin -u 2181 zookep && logger "<解决依赖> 创建用户 zookep 成功!"
fi

# 安装程序

tar xf ${ZOO_PACKET} -C ${INSTALL_BASE}            && logger "<安装程序> ${ZOO_PACKET} ==> ${INSTALL_BASE} 解压成功!"
result=$(ln -sv ${INSTALL_BASE}/zookeeper-3.4.9/ ${INSTALL_BASE}/zookeeper 2>&1) ; logger "<安装程序> ${result}"

rm -f /opt/zookeeper/zookeeper-3.4.9.jar.{asc,md5,sha1} &&
rm -f /opt/zookeeper/bin/{README.txt,*.cmd}             &&
rm -rf /opt/zookeeper/lib/{*.txt,cobertura,jdiff}       && 
rm -rf /opt/zookeeper/{recipes,src,docs,contrib,dist-maven,*.txt,*.xml} && logger "<安装程序> 清理目录"

chown -R root:root /opt/zookeeper/      && logger "<安装程序> 修改 ZOO_HOME 目录属主属组为 root"
chown -R root:root ${ZOO_BASE}          && logger "<安装程序> 修改 ZOO_BASE 目录属主属组为 root"
chown -R zookep:zookep ${ZOO_BASE}/data && logger "<安装程序> 修改 data 目录属主属组为 zookep"
chown -R zookep:zookep ${ZOO_BASE}/logs && logger "<安装程序> 修改 logs 目录属主属组为 zookep"
chown -R zookep:zookep ${ZOO_BASE}/run  && logger "<安装程序> 修改 run  目录属主属组为 zookep"

result=$(ln -sv ${ZOO_BASE}/data/ $(dirname ${ZOO_BASE})/data 2>&1)             && logger "<安装程序> ${result}"
result=$(ln -sv ${ZOO_BASE}/logs/ $(dirname ${ZOO_BASE})/logs 2>&1)             && logger "<安装程序> ${result}"
result=$(ln -sv ${ZOO_BASE}/zookeeper.sh $(dirname ${ZOO_BASE})/zookeeper 2>&1) && logger "<安装程序> ${result}"

# 修改配置
CONF_CONTENT="
tickTime=2000
\ninitLimit=10
\nsyncLimit=5
\n
\ndataDir=${ZOO_DATA_DIR}
\ndataLogDir=${ZOO_DATA_DIR}
\n
\nautopurge.purgeInterval=24
\nautopurge.snapRetainCount=500
\n
\nclientPort=2181
\n"

x=1
for host in ${ZOO_HOST_LIST}; do
    CONF_CONTENT="$CONF_CONTENT\nserver.${x}=${host}:2888:3888"
    let x++
done

echo -e $CONF_CONTENT > ${ZOO_CONF_DIR}/zoo.cfg && logger  "<修改配置> 生成 ${ZOO_CONF_DIR}/zoo.cfg 配置文件成功!"
echo    ${ZOO_MYID}   > ${ZOO_DATA_DIR}/myid    &&  logger "<修改配置> 生成 ${ZOO_DATA_DIR}/myid <myid:${ZOO_MYID}> 配置文件成功!"

# 启动程序
read -p "是否启动服务 [y/n]: " result && result=${result:-NULL}
[ ${result} != "y" ] && exit 1

${ZOO_BASE}/zookeeper.sh start
sleep 1
ps -ef | grep java |  grep zookeeper 
