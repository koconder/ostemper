#!/bin/sh
# Wrapper around checkbashisms/shellcheck/whatever other shell checkers I can find
#
# Source: https://github.com/Winetricks/winetricks/blob/master/tests/shell-checks
# 
# Copyright (C) 2016 Austin English
#
# This software comes with ABSOLUTELY NO WARRANTY.
#
# This is free software, placed under the terms of the GNU Lesser
# Public License version 2.1 (or later), as published by the Free
# Software Foundation. Please see the file COPYING for details.

set -e
set -x

w_die() {
    echo "$* failed"
    exit 1
}

w_try() {
    "$@"
    status=$?
    if test $status -ne 0; then
        w_die "Note: command $* returned status $status.  Aborting."
    fi
}

#command bashate --help > /dev/null || w_die "bashate must be installed!"
command checkbashisms --help > /dev/null || w_die "checkbashisms must be installed!"
command shellcheck --version > /dev/null || w_die "shellcheck must be installed!"

# Different versions can give different results:

#echo "======================== Begin bashate version info ==========================="
## bashate doesn't have a --version option (as of bashate-0.3.1)
#bashate --version
#echo "======================== End bashate version info ==========================="

echo "======================== Begin checkbashisms version info ==========================="
checkbashisms --version
echo "======================== End checkbashisms version info ==========================="

echo "======================== Begin shellcheck version info ==========================="
shellcheck --version
echo "======================== End shellcheck version info ==========================="

# Use git ls-files if available, this prevents 'finding' scripts that aren't checked into git.
# E.g., if patching foo fails, then foo.orig would also be 'found'.
# The find fallback is for non git users, e.g., distros packaging winetricks or end users
# running shell-checks from a tarball download.
if [ -d .git ] ; then
    files_to_check="$(git ls-files | xargs file | grep -e 'POSIX shell script' | cut -d : -f1)"
else
    files_to_check="$(find . -type f -exec file {} \; | grep -e 'POSIX shell script' | cut -d : -f1)"
fi

for shellscript in $files_to_check; do
    echo "Checking ${shellscript} for bashisms:"
    w_try checkbashisms --posix "${shellscript}"

    echo "Checking ${shellscript} with shellcheck:"
    w_try shellcheck -s sh "${shellscript}"

    #echo "Checking ${shellscript} with bashate:"
    # Can't ignore individual things for now, filed bug:
    # https://bugs.launchpad.net/bash8/+bug/1698088
    # E006=line length check
    # E010=do/while same line (in some perl in winetricks)
    #w_try bashate -i E006,E010 "${shellscript}"
done