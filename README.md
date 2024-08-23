# Screenux - GNU Screen for humans

Run commands or scripts in screen with logging to file

## Features

- run in background
- custom log file name
    - unique timestamp suffix to logfile (default)
    - single logfile for multiple runs (option)
- custom output dir (default ./)
- realtime writing to logfile
- print run info after run
- standalone script if screen version > 4.06.02

## Example 1 - Simple run
`source screenux.sh`

`screenux_run "echo hello`

### Before run
```
gndps:screenux gndps$ tree -L 2 -I screen_version_mgmt
.
├── README.md
├── screenux.sh
└── script_test.sh

1 directory, 3 files

```
### Run command
```
gndps:screenux gndps$ screenux_run "echo hello"

===== screenux run success =====
Log file: /Users/gndps/github/screenux/screenux_run/screenux_run-20240822-185925-0c57.log
View logs: tail -Fn 0 /Users/gndps/github/screenux/screenux_run/screenux_run-20240822-185925-0c57.log
Attach session: /Users/gndps/github/screenux/screen_version_mgmt/screen491 -r screenux_run-20240822-185925-0c57
Detach after attaching: Ctrl+A, D
================================

```

### After run
```
gndps:screenux gndps$ tree -L 2 -I screen_version_mgmt
.
├── README.md
├── screenux.sh
├── screenux_run
│   └── screenux_run-20240822-185925-0c57.log
└── script_test.sh

2 directories, 4 files
```

### Logfile
```
gndps:screenux gndps$ cat screenux_run/screenux_run-20240822-185925-0c57.log
[Thu 22 Aug 2024 18:59:25 PDT] Running command:
echo hello
---------
hello
```

## Example 2 - Named run with custom output folder
`source screenux.sh`

`screenux_run -o outputs -n myrun "echo hello"`

### Run command
```
gndps:screenux gndps$ screenux_run -o outputs -n myrun "echo hello"

===== screenux run success =====
Log file: outputs/myrun/myrun-20240822-190034-3fa7.log
View logs: tail -Fn 0 outputs/myrun/myrun-20240822-190034-3fa7.log
Attach session: /Users/gndps/github/screenux/screen_version_mgmt/screen491 -r myrun
Detach after attaching: Ctrl+A, D
================================

```

### After run
```
gndps:screenux gndps$ tree -L 3 -I screen_version_mgmt
.
├── README.md
├── outputs
│   └── myrun
│       └── myrun-20240822-190034-3fa7.log
├── screenux.sh
├── screenux_run
│   └── screenux_run-20240822-185925-0c57.log
└── script_test.sh

4 directories, 5 files
```
### Logfile
```
gndps:screenux gndps$ cat outputs/myrun/myrun-20240822-190034-3fa7.log 
[Thu 22 Aug 2024 19:00:34 PDT] Running command:
echo hello
---------
hello
```

## Example 3 - Logfile with no suffix
`source screenux.sh`

`screenux_run -o outputs -n runs_concat -ns "echo hello 1"`
### Run command
```
gndps:screenux gndps$ screenux_run -o outputs -n runs_concat -ns "echo hello 1"

===== screenux run success =====
Log file: outputs/runs_concat.log
View logs: tail -Fn 0 outputs/runs_concat.log
Attach session: /Users/gndps/github/screenux/screen_version_mgmt/screen491 -r runs_concat
Detach after attaching: Ctrl+A, D
================================

```
### After run
```
gndps:screenux gndps$ tree -L 3 -I screen_version_mgmt
.
├── README.md
├── outputs
│   ├── myrun
│   │   └── myrun-20240822-190034-3fa7.log
│   └── runs_concat.log
├── screenux.sh
├── screenux_run
│   └── screenux_run-20240822-185925-0c57.log
└── script_test.sh

4 directories, 6 files
```
### Subsequent run with same logfile name
```
gndps:screenux gndps$ screenux_run -o outputs -n runs_concat -ns "echo hello 2"

===== screenux run success =====
Log file: outputs/runs_concat.log
View logs: tail -Fn 0 outputs/runs_concat.log
Attach session: /Users/gndps/github/screenux/screen_version_mgmt/screen491 -r runs_concat
Detach after attaching: Ctrl+A, D
================================

```
### Concatenated logfile
```
gndps:screenux gndps$ cat outputs/runs_concat.log 
[Thu 22 Aug 2024 19:01:45 PDT] Running command:
echo hello 1
---------
hello 1
[Thu 22 Aug 2024 19:02:00 PDT] Running command:
echo hello 2
---------
hello 2

```


