task.sh
=======

> A bash-based task runner

A make/rake-like task runner using simple bash functions defined in a Taskfile.

Unlike other task runners additional arguments are forwarded along to tasks.


Taskfile
--------

```bash
@project "project-name"

Task:taskname() {
  : @desc "task description"

  Runner::run your_command "$@"
}
```

Usage
-----

### Commands
```
ls|list               list tasks
```

### Options
```
-f|--taskfile <file>  path to Taskfile
-h|--help             show help
-n|--dry-run          dry run mode
-V|--verbose          verbose mode
-v|--version          print version
--                    end of options
```

### Environment
```
NOCOLOR               disable color output                   default  ''         (false)
COLOR_TASK            escape sequence to color task names    default: '\x1b036m' (cyan)
COLOR_ERROR           escape sequence to color error title   default: '\x1b031m' (red)
```

### Examples

```
$ task ls                    # list tasks
$ task test --strict         # call the Task::test() function with the argument "--strict"
$ task -n get theme          # dry run mode -- print "Task::get theme"
$ task -V get theme          # verbose mode -- print "Task::get theme", plus Runner::run commands
$ task update -- -n name     # call the Task::update() function with the arguments "-n" "name"
```

Install
-------

```bash
BINDIR=/usr/local/bin
curl https://raw.githubusercontent.com/alissa-huskey/task.sh/master/task.sh > $BINDIR/task
chmod +x $BINDIR/task
```

Alternatives
------------

* [taskit](https://github.com/kjkuan/taskit)

Requirements
----

* bash 3+
* sed
* sort
* column

Meta
----

* repo: <https://github.com/alissa-huskey/task.sh>
