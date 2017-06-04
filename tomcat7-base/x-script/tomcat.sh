#!/bin/bash
#=======================================================================#
#                                                                       #
#         文件名:    tomcat.sh                                          #
#         描述信息:  tomcat7项目启动脚本                                #
#         当前版本:  2.0                                                #
#         创建时间:  2017年6月9日 11:26:37                              #
#         功能介绍:  1. 启动tomcat并显示catalina.out日志                #
#                    2. 清理日志功能                                    #
#                                                                       #
#========================================================================

# 基础启动参数
CATALINA_OPTS="-server -Xms4096m -Xmx4096m -XX:PermSize=128m -XX:MaxPermSize=512m"

# 开启gc日志
CATALINA_OPTS="$CATALINA_OPTS
 -XX:+PrintGCDateStamps 
 -XX:+PrintGCDetails
 -Xloggc:$(dirname $(readlink -f $0))../logs/gc.log"

# 开启HeapDump
CATALINA_OPTS="$CATALINA_OPTS
 -XX:+HeapDumpOnOutOfMemoryError 
 -XX:HeapDumpPath=$(dirname $(readlink -f $0))../logs/heap.bin"

# 开启JXM功能 (**注意修改hostname及端口**)
#CATALINA_OPTS="$CATALINA_OPTS
# -Djava.rmi.server.hostname=VM01
# -Dcom.sun.management.jmxremote=true
# -Dcom.sun.management.jmxremote.port=18080
# -Dcom.sun.management.jmxremote.ssl=false
# -Dcom.sun.management.jmxremote.authenticate=false"


#=======================================================================#
#    说明: 公共变量
#=======================================================================#
SCRIPT_PWD=$(dirname $(readlink -f $0))
DAEMON_SCRIPT=${SCRIPT_PWD}/../x-bin/catalina.sh
CATALINA_PID=${SCRIPT_PWD}/../run/catalina.pid

#=======================================================================#
#    函数: start()
#    参数: <NULL> 启动后不显示日志
#          <-p>   启动后显示日志
#    说明: 启动实例
#=======================================================================#
start() {
    $DAEMON_SCRIPT start
    [ "$1" == "-p" ] && tail -0f $CATALINA_BASE/logs/catalina.out
}

#=======================================================================#
#    函数: stop()
#    参数: <NULL> 停止catalina实例
#          <-f>   强制停止catalina实例
#    说明: 停止实例
#=======================================================================#
stop() {
    arg=${1:-"NULL"}
    [ ! -e ${CATALINA_PID} ] && return 1
    pid=$(cat ${CATALINA_PID})
    [ -z ${CATALINA_PID} ] && return 1
    if [ ! -e "/proc/${pid}" ]; then
        echo "PID:${_pid} 此进程不存在!"
        rm ${CATALINA_PID}
        return 1
    fi

    echo "PID:${pid} 准备Kill此进程!"
    
    [ $arg == "-f" ] && kill -9 ${pid} \
                     || kill -15 ${pid}

    while [ -e "/proc/${pid}" ]; do
        echo -n "+"
        sleep 1
    done
        echo 成功!
        rm ${CATALINA_PID}
}

#=======================================================================#
#    函数: clean-log()
#    参数: <$1> 保留最新几份数据
#    说明: 清楚日志
#=======================================================================#
clean-log() {
    CATALINA_LOG=${CATALINA_BASE}/logs
    num=$1
    let num+=1

    cd ${CATALINA_LOG}
    fileListL[0]="$(ls -t catalina.*.out 2> /dev/null | tail -n +${num})"
    fileListL[1]="$(ls -t catalina.*.log 2> /dev/null | tail -n +${num})"
    fileListL[2]="$(ls -t manager.*.log 2> /dev/null | tail -n +${num})"
    fileListL[3]="$(ls -t host-manager.*.log 2> /dev/null | tail -n +${num})"
    fileListL[4]="$(ls -t localhost.*.log 2> /dev/null | tail -n +${num})"
    fileListL[5]="$(ls -t localhost_access_log.*.txt 2> /dev/null | tail -n +${num})"

    for fileList in ${fileListL[@]}; do
        [ ! -z fileList ]  &&
        for file in $fileList; do
            echo Deleting: $file
            rm $file
        done
    done
}

#=======================================================================#
#    函数: clean-cache()
#    参数: <$1> 保留最新几份数据
#    说明: 清空catalina-base下的缓存文件
#=======================================================================#
clean-cache() {
    cd ${CATALINA_BASE}/work
    rm -r $(ls . | grep -v .gitkeep)

    cd ${CATALINA_BASE}/temp
    rm -r $(ls . | grep -v .gitkeep)

    cd ${CATALINA_BASE}/conf
    rm -r Catalina
}

case $1 in

    start)
        shift
        [ "$1" == "-p" ] && start -p \
                         || start
    ;;

    stop)
        stop
    ;;
    clean-log)
        shift
        [ -z $1 ] && clean-log 2 \
                  || clean-log $1
    ;;
    clean-cache)
        clean-cache
    ;;
    help)
        echo -e "使用方法:
           start [-p]: 启动服务,-d为不输出日志
                 stop: 停止服务
        clean-log [n]: 清楚日志, n为保留最近几份日志,留空默认为2,清空为0\n
        clean-cache  : 清楚缓存文件"
    ;;
    *)
        echo $"Usage: $0 {start|stop|clean-log|clean-cache|help}"
        exit 2
esac

