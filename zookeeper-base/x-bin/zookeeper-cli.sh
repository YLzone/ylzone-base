_ZOO_HOME=${_ZOO_HOME:-/opt/zookeeper}
_ZOO_BASE=$(dirname $(dirname $(readlink -f $0)))
export ZOOCFGDIR=${ZOOCFGDIR:-${_ZOO_BASE}/conf}
export ZOO_LOG_DIR=${ZOO_LOG_DIR:-${_ZOO_BASE}/logs}
export ZOO_LOG4J_PROP=${ZOO_LOG4J_PROP:-INFO,CONSOLE}
${_ZOO_HOME}/bin/zkCli.sh "$@"
