_SCRIPT_PWD=$(dirname $(readlink -f $0))
_CATALINA_HOME=${_CATALINA_HOME:-/opt/tomcat7}
_CATALINA_BASE=${_CATALINA_BASE:-$(dirname ${_SCRIPT_PWD})}
export CATALINA_BASE=${CATALINA_BASE:-$_CATALINA_BASE}
export CATALINA_PID=${CATALINA_PID:-${_CATALINA_BASE}/run/catalina.pid}
${_CATALINA_HOME}/bin/catalina.sh "$@"

