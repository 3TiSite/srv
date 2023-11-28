_init() {
  local pwd=$(pwd)
  local dir=$(readlink -f "$BASH_SOURCE")
  dirdocker=${dir%/*/*}/conf/docker
  if [ -d "$dirdocker" ]; then
    cd $dirdocker
    local i
    for i in $@; do
      set -o allexport
      source "$i".sh
      set +o allexport
    done

    cd $pwd
  fi

}
_init db host smtp kv
unset -f _init
