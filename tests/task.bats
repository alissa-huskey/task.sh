#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
rootdir="$( cd -P "${BATS_TEST_DIRNAME}/.." && echo "$PWD" )"
export NOCOLOR=true

@test "task.sh" {
  run "${rootdir}/task.sh"
  assert_failure
  assert_output --regexp "^Usage: task"
}

@test "task.sh -v|--version" {
  run "${rootdir}/task.sh" -v
  assert_output --regexp "^task.sh version [0-9.]+$"
}

@test "task.sh -h|--help" {
  run "${rootdir}/task.sh" -h
  assert_output --regexp "^Usage: task"
}

@test "task.sh -f|--taskfile <file>" {
  run "${rootdir}/task.sh" -f tests/fixtures/Taskfile ls
  assert_success
  assert_line --regexp "^[[:space:]]*test-taskfile tasks$"
}

@test "task.sh -f|--taskfile <missing-file>" {
  run "${rootdir}/task.sh" -f xxx
  assert_failure
  assert_output "task.sh [ERROR] Not a valid Taskfile: 'xxx'"
}

@test "task.sh -V|--verbose <task>" {
  run "${rootdir}/task.sh" -f tests/fixtures/Taskfile -V test
  assert_success
  assert_line --index 0 "task.sh> Task::test"
  assert_line --index 1 "task.sh:test> echo running tests..."
  assert_line --index 2 "running tests..."
  assert_equal 3 "${#lines[@]}"
}

@test "task.sh <task>" {
  run "${rootdir}/task.sh" -n test
  assert_success
  assert_output "task.sh> Task::test"
}

@test "task.sh <task> <arg>" {
  run "${rootdir}/task.sh" -n test -r
  assert_success
  assert_output "task.sh> Task::test -r"
}

@test "task.sh <task> -- <arg>" {
  run "${rootdir}/task.sh" -n test -- --help
  assert_success
  assert_output "task.sh> Task::test --help"
}

@test "task.sh ls|list" {
  # task.sh tasks
  # GLOBAL
  # list	List tasks
  # PROJECT
  # install    install task.sh
  # reinstall  reinstall task.sh
  # test       run tests
  # uninstall  uninstall task.sh

  run "${rootdir}/task.sh" ls
  assert_success
  assert_equal 8 ${#lines[@]}

  assert_line --index 0 "task.sh tasks"
  assert_line --regexp --index 1 "^[ ]+GLOBAL$"
  assert_line --regexp --index 2 "^[ ]+list[[:space:]]*List tasks$"
  assert_line --regexp --index 3 "^[ ]+PROJECT$"
  assert_line --regexp --index 4 "^[ ]+install[[:space:]]*install task.sh$"
  assert_line --regexp --index 5 "^[ ]+reinstall[[:space:]]*reinstall task.sh$"
  assert_line --regexp --index 6 "^[ ]+test[[:space:]]*run tests$"
  assert_line --regexp --index 7 "^[ ]+uninstall[[:space:]]*uninstall task.sh$"
}

@test "task.sh <invalid-task>" {
  run "${rootdir}/task.sh" invalid
  assert_failure
  assert_output "task.sh [ERROR] No task found for: 'invalid'"
}
