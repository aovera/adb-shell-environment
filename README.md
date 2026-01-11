# adb-shell-environment
A simple command line tool to setup(transplant) programs in an adb shell

This project targets users who need a more capable shell environment than the default adb shell, without root access and without modifying system partitions.


Overview


Android’s adb shell provides limited tooling and lacks a usable Unix userland.
Termux provides a full userspace but is sandboxed as an application.


This project bridges part of that gap by selectively transplanting Termux binaries, shared libraries, and required runtime files into the adb shell filesystem using rish(look https://github.com/RikkaApps/Shizuku).


No root required

No chroot or proot

No system partition modification

Runtime dependencies are user-defined

Setup:

Install termux app from f-droid and finish termux setup.

Install shizuku app and go through activation and rish extraction steps.

Install the package you want using termux package manager ```pkg```


How it works

The script runs inside Termux

A target program is specified:

```./transplant.sh htop```


The script:

resolves the executable path

extracts shared library dependencies using ldd

filters out system libraries (/system, /apex)

stages files under /sdcard/Download/rish_files

Files are copied into the adb shell environment using rish

Executable permissions are restored (required due to sdcard filesystem behavior)

Optional runtime files are installed via a user-maintained extras database

Runtime dependencies (extras system)

Some programs require additional files such as runtime data, configuration directories, or terminfo entries.

These are handled via a simple declarative database embedded in the script.

Format
program|type|source|destination

Example
nvim|dir|/data/data/com.termux/files/usr/share/nvim|/data/data/com.android.shell/usr/share/nvim
htop|dir|/data/data/com.termux/files/usr/share/terminfo|/data/data/com.android.shell/home/.terminfo


When a program is transplanted, matching entries are applied automatically.

The database is intended to be extended incrementally as new programs are tested.

Environment initialization

A minimal rc.sh is staged in /sdcard/Download/rish_files and installed only if missing.

This script configures:

PATH

LD_LIBRARY_PATH

HOME

TERM

temporary directories

Users are expected to customize it as needed.

Usage
Transplant a program
```./transplant.sh <program>```

Enter the environment
```alias rishenv="rish -c 'source /data/data/com.android.shell/usr/bin/rc.sh'"```

Compatibility

Compatibility depends on SELinux policy, runtime behavior, and hardcoded paths.
The following reflects observed behavior and is expected to evolve.

Generally working

These tools typically work after transplanting, sometimes with extra runtime files:

```htop```

```fish```

```nvim```

```curl```

```wget```

```strace```


Partially working

These may run but exhibit limitations or missing functionality:

```bash```

Not working / known broken

These typically fail due to SELinux restrictions or missing kernel features:

```tmux```

```screen```



Limitations

SELinux restrictions remain in effect

No automatic dependency resolution beyond ldd

Runtime-loaded plugins may not be detected

Hardcoded Termux paths may break binaries

This is not a package manager

Security considerations

No privileges are escalated

SELinux policy is not modified

No system files are altered

All operations occur within app-accessible paths
