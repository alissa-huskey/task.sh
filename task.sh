#!/usr/bin/env bash

set -e -o pipefail
set +o posix

Task::list() {
  : @desc "List tasks"

  local script tab=$'\t' indent="    "

  read -d '' -r script <<SCRIPT || :
  /^Task::/, /^\}/ {
    /^Task::/ {
      s/Task::([^(]+).*$/${indent}${color_task}\1${color_off}/
      N

      /@desc/ {
        s/[ ]+: @desc[ ]+"(.*)"/${tab}\1/
      }
      s/\n//g
      p
    }
  }
SCRIPT

  printf "\n%stasks\n\n" "${project:+$project }"
  {
    echo -e "${indent}GLOBAL"
    echo    "__NL__"
    runner::sed -n "${script}" "${0}" | sort
    echo    "__NL__"

    echo -e "${indent}PROJECT"
    echo    "__NL__"
    runner::sed -n "${script}" "${taskfile}" | sort
  }                                                    \
  | column -s $'\t' -t                                 \
  | runner::sed "s/__NL__//g"
  echo
}

Runner::run() {
  if runner::is_verbose; then
    echo -e "${me}${color_task}:${task#Task::}>${color_off}" "$@"
  fi

  "$@"
}

runner::abort() {
  local ec=$1 ; shift
  runner::error "$*"
  exit $ec
}

runner::error() {
  echo -e "${me} ${color_error}[ERROR]${color_off} $*"
}

runner::version() {
  echo "task.sh version ${version}"
}

runner::usage() {
  echo "Usage: ${me} [-n] [-V] [-f <file>] <task> [<arg> ...]"
  echo "       (hint: task list)"
}

runner::args() {
  taskargs=()
  local optend shiftnum

  if [[ $# -eq 0 ]]; then
    runner::usage
    exit $ec_argument
  fi

  while [[ $# -gt 0 ]]; do
    if [[ -n "$optend" ]]; then
      taskargs+=( "$1" )
      shift
      continue
    fi

    shiftnum=1
    case $1 in
      # forward all options past the --
      --)               optend=1                          ;;
      -f|--taskfile)    taskfile="$2"    ; shiftnum=2     ;;
      -V|--verbose)     is_verbose=1                      ;;
      -n|--dry-run)     is_dryrun=1                       ;;
      -h|--help|help)   runner::usage    ; exit           ;;
      -v|--version)     runner::version  ; exit           ;;

      # no args starting with - will be the task name
      -)                taskargs+=( "$1" )                ;;

      *)
        if [[ -z "$task" ]]; then
          task="$1"
        else
          taskargs+=( "$1" )
        fi
                                                          ;;
    esac
    shift ${shiftnum}
  done
}

runner::run() {
  if runner::is_dryrun || runner::is_verbose; then
    echo -e "${me}${color_task}>${color_off}" "$@"

    if runner::is_dryrun; then
      return
    fi
  fi

  "$@"
}

runner::is_dryrun() {
  [[ -n "$is_dryrun" ]]
}

runner::is_verbose() {
  [[ -n "$is_verbose" ]]
}

runner::init() {
  local sed_version
  me="${0##*/}"

  if [[ ! $NOCOLOR ]]; then
    color_off='\x1b[0m'

    # shellcheck disable=SC2153 # (Possible misspelling)
    color_task="${COLOR_TASK}"    # get from environment
    : "${color_task:=\x1b[36m}"   # set default

    # shellcheck disable=SC2153 # (Possible misspelling)
    color_error="${COLOR_ERROR}"  # get from environment
    : "${color_error:=\x1b[31m}"   # set default
  fi

  read -r sed_version < <(sed --version 2>&1)
  if [[ "$sed_version" =~ 'GNU'  ]]; then
    sed_varient="GNU"
  elif [[ "$sed_version" =~ usage:.*-E ]]; then
    sed_varient="BSD"
  fi
}

runner::loadfile() {
  : "${taskfile:=./Taskfile}"

  if [[ ! -s "${taskfile}" ]]; then
    runner::abort $ec_taskfile "Not a valid Taskfile: '${taskfile}'"
  fi

  source "${taskfile}"

  if [[ -z "${task}" ]]; then
    runner::abort $ec_argument "No task found for: '${taskargs[*]}'"
  fi

  # task aliases
  case "${task}" in
    ls)   task="list"
  esac

  if ! declare -F "Task::${task}" > /dev/null; then
    runner::abort $ec_argument "No task found for: '$task'"
  fi

  task="Task::${task}"
  read -r project < <(runner::sed -n '/@project/ { s/[ ]*: @project[ ]+"(.*)"/\1/p ; q ; }' "${taskfile}")

}

runner::sed() {
  local -a flags

  case "$sed_varient" in
    GNU)  flags+=( "-r" )    ;;
    BSD)  flags+=( "-E" )    ;;
  esac

  if [[ "$1" == "-n" ]]; then
    flags+=( "-n" )
    shift
  fi

  sed ${flags[@]} -e "$@"
}

runner::main() {
  local me project task taskfile taskargs
  local sed_varient is_dryrun version="0.1"
  local color_off color_task color_error
  local ec_ok=0 ec_error=1 ec_taskfile=2 ec_argument=3 ec_taskfailed=4

  runner::init

  runner::args ${1:+"$@"}
  runner::loadfile

  runner::run ${task} ${taskargs[0]:+"${taskargs[@]}"}
}

runner::main ${1:+"$@"}
