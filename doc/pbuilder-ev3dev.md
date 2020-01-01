% PBUILDER-EV3DEV(1) | User's Manual
% David Lechner
% October 2016

# NAME

pbuilder-ev3dev - Package builder for ev3dev Debian packages

# SYNOPSIS

OS=*os* ARCH=*arch* DIST=*dist* pbuilder-ev3dev *command*

# DESCRIPTION

Builds Debian packages in a chroot using git-buildpackage and pbuilder (and qemu
if needed).

# USAGE

*os*
: The target operating system. This can be "debian", "rasbian", or "ubuntu".

*arch*
: The target architecture. This can be "amd64", "i386", "arm64", "armhf" or
"armel". Note: Raspbian only supports "armhf" and Ubuntu does not support
"armhf" or "armel".

*dist*
: The target distribution. For Debian/Raspbian, this can be "jessie", "stretch"
or "buster". For Ubuntu, this can be "trusty", "xenial" or "bionic".

*command*
: The command to run. See **COMMANDS** section below.

# COMMANDS

**base**
: Creates or updates the root file system for the specified os/dist/arch. This
must be run before the **build** command.

**build**
: Builds the Debian package in the current working directory. The package must
be setup to use **git-buildpackage**.

**dev-build**
: Same as **build**, but allows uncommitted changes.

**dsc-build** *dsc-file*
: Builds the Debian package from the specified *dsc-file*.

# FILES

`$HOME/pbuilder-ev3dev/$OS/base-$DIST-$ARCH.tgz`
: The root file system created by the **base** command.

`$HOME/pbuilder-ev3dev/$OS/$DIST-$ARCH/`
: Directory where the generated Debian packages are saved.

# ENVIRONMENT

`OS`, `ARCH`, `DIST`
: See **USAGE** section above.

`GBP_OPTIONS`
: Additional `git-buildpackage` options.

`PBUILDER_OPTIONS`
: Additional `pbuilder` options. Useful options include `--binary-arch` to only
build the binary packages and not the architecture independent (all) packages and
`"--debbuildopts '-sa'"` to force uploading the orig source tarball.
