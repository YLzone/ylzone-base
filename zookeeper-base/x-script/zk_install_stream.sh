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

#git clone git@try.gogs.io:yangli886/ylzone-base.git /tmp/ylzone-base || { logger "git 失败"; exit 1; }

#mkdir -v /data/zookeeper

#mv /tmp/ylzone-base/zookeeper-base /data/zookeeper/.zookeeper-base

exec /data/zookeeper/.zookeeper-base/x-script/zk_install.sh

