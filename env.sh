local pwd=$(pwd)
local dir=$(readlink -f "$BASH_SOURCE")
local conf=${dir%/*/*}/conf
_init() {
  local i
  for i in $@; do
    set -o allexport
    source "$i".sh
    set +o allexport
  done

  cd $pwd
}
cd $conf/docker
_init db host smtp r
cd $conf/srv
_init warn
unset -f _init
