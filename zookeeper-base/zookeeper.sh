#!/bin/bash
#=======================================================================#
#                                                                       #
#         文件名:    zookeeper-server.sh                                #
#         描述信息:  tomcat项目启动脚本                                 #
#         适用版本:  3.4.9                                              #
#         当前版本:  1.1                                                #
#         创建时间:  2017年6月5日 17:00:00                              #
#         功能介绍:  启动脚本                                           #
#                                                                       #
#========================================================================

#=======================================================================#
#    基础变量:
#             1.配置文件目录
#             2.数据目录
#             3.日志目录
#             4.PID目录
#=======================================================================#
_BASE_PWD=$(dirname $(readlink -f $0))
_BASE_CONF_DIR=${_BASE_PWD}/conf
_BASE_DATA_DIR=${_BASE_PWD}/data
_BASE_LOG_DIR=${_BASE_PWD}/logs
_BASE_PID_DIR=${_BASE_PWD}/run

#=======================================================================#
#    项目变量:
#             可根据具体项目或程序所需设置
#=======================================================================#
_ZOO_HOME=${_BASE_PWD}

#=======================================================================#
#    输出环境变量
#=======================================================================#
#export ZOOCFGDIR ZOO_LOG_DIR ZOOPIDFILE

#=======================================================================#
#    函数: logger
#    参数: <$1> 日志内容
#    说明: 格式化记录日志
#=======================================================================#
logger() {

    echo "[$(date +%F_%T)] - [${FUNCNAME[1]}] - $1"

}

#=======================================================================#
#    函数: start
#    参数: NULL
#    说明: 启动函数
#=======================================================================#
start() {
	
	if [ $(id -u) -eq 0 ]; then
		logger "但前用户为 root 自动切换为 zookep 为运行用户"
                runuser zookep -s /bin/bash -c "${_BASE_PWD}/x-bin/zookeeper-server.sh start"
	else
		${_BASE_PWD}/x-bin/zookeeper-server.sh star
	fi

}

#=======================================================================#
#    函数: stop
#    参数: NULL
#    说明: 启动函数
#=======================================================================#
stop() {

        if [ $(id -u) -eq 0 ]; then
                logger "但前用户为 root 自动切换为 zookep 为运行用户"
                runuser zookep -s /bin/bash -c "${_BASE_PWD}/x-bin/zookeeper-server.sh stop"
        else
                ${_BASE_PWD}/x-bin/zookeeper-server.sh star
        fi
}

#=======================================================================#
#    函数: clean_init
#    参数: NULL
#    说明: 用于初次部署时清空操作目录。
#=======================================================================#
init_clean() {

    if [ -z ${_BASE_PWD} ]; then
        logger "基础目录错误"
        return 1
    fi

    if [ -e ${_BASE_PWD}/data ]; then
        rm -rf ${_BASE_PWD}/data/* && logger "clean data successfull!" \
                                   || logger "clean data failed"
    fi

    if [ -e ${_BASE_PWD}/logs ]; then
        rm -rf ${_BASE_PWD}/logs/* && logger "clean logs successfull!" \
                                   || logger "clean logs failed"
    fi

    if [ -e ${_BASE_PWD}/run ]; then
        rm -rf ${_BASE_PWD}/run/* && logger "clean pid successfull!" \
                                  || logger "clean pid failed"
    fi
}

#=======================================================================#
#    Main
#=======================================================================#
case $1 in

	start)
		start
	;;

	stop)
		stop
	;;

	status)
		${_ZOO_HOME}/bin/zkServer.sh status
	;;

	init-clean)
		init_clean
	;;

	client)
		${_ZOO_HOME}/bin/zkCli.sh
	;;

	*)
		echo -e $"\nUsage: $0 {start|stop|status|clean-init|help}\n"
                exit 1
	;;
esac
