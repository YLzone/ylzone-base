#!/bin/bash
#=======================================================================#
#                                                                       #
#         文件名:    tomcat_uninstal.sh                                 #
#         描述信息:  tomcat自动写在脚本                                 #
#         当前版本:  2.0                                                #
#         创建时间:  2017年6月9日                                       #
#         功能介绍:  自动化卸载                                         #
#                                                                       #
#========================================================================

rm -rf /tmp/ylzone-base
rm -rf /tmp/apache-tomcat-*.tar.gz
rm -rf /opt/apache-tomcat-*
rm -f  /opt/tomcat7
rm -rf /data/tomcat
