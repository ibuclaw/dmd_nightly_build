

This repo is intended house the nightly build for the asm.dlang.org site.  It will build dmd/druntime/phobos using the update.sh script.  The build is done in it's own directory so it doesn't disrupt the current binaries.  After the build, the binaries are installed (install.sh) to ../dmd_nightly.

TODO: if update.sh fails then the script should not perform the install

update.sh: script to update repos and build
install.sh: installs the build to ../dmd_nightly
nightly_update_and_install.sh: cron job script to update and install

last_build: log of last build
build_history: log of all builds