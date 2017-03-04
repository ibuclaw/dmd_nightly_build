#!/usr/bin/env zsh

# Run this script to install or update your dmd toolchain from
# github.
#
# Make sure zsh is installed. You may need to change the shebang.
#
# First run, create a working directory, e.g. /path/to/d/. Then run
# this script from that directory (the location of the script itself
# doesn't matter). It will create the following subdirectories:
# /path/to/d/dmd, /path/to/d/druntime, and /path/to/d/phobos.
# Then it will fetch all corresponding projects from github and
# build them fresh.
#
# On an ongoing basis, to update your toolchain from github go again
# to the same directory (in our example /path/to/d) and run the script
# again. The script will detect that directories exist and will do an
# update.
#

setopt err_exit

local projects
typeset -a projects
projects=(dmd druntime phobos)
# Working directory
local wd=$(pwd)
# Configuration
local makecmd=gmake
local host_dc="$wd/../dmd_nightly/freebsd/bin64/dmd"
local target_dc="$wd/dmd/src/dmd"
local parallel=8
local model=64
# List of projects to install vs. update. Their disjoint union is
# $projects.
local toInstall toUpdate
typeset -a toInstall toUpdate
# Mess to go here
local tempdir=$(mktemp -d /tmp/dmd-update.XXX)

#
# Take care of the command line arguments
#
function handleCmdLine() {
    local arg
    for arg in $*; do
        case $arg in
            (--tag=*)
            tag="`echo $arg | sed 's/[-a-zA-Z0-9]*=//'`"
            ;;
            (install)
            install="yes"
            ;;
            (*)
            echo "Error: $arg not recognized." >&2
            exit 1
            ;;
        esac
    done

    if [[ ! -z $tag ]]; then
        wd+="/$tag"
        mkdir -p "$wd"
    fi
}

#
# Confirm correct choices
#
function confirmChoices() {
    function joinWithWorkingDir() {
        for i in $*; do
            echo "$wd/$i"
        done
    }

    for project in $projects; do
        if [ -e "$wd/$project" ]; then
            toUpdate=($toUpdate "$project")
        else
            toInstall=($toInstall "$project")
        fi
    done
    if [[ ! -z $toInstall ]]; then
        echo "*** The following projects will be INSTALLED:"
        joinWithWorkingDir ${toInstall}
        echo "*** Note: this script assumes you have a github account set up."
    fi
    if [[ ! -z $toUpdate ]]; then
        echo "*** The following projects will be UPDATED:"
        joinWithWorkingDir ${toUpdate}
    fi

    # Removed for sake of automation
    #echo "Is this what you want?"
    #local yn
    #while true; do
        #read yn
        #case $yn in
            #[Yy]* ) break;;
            #[Nn]* ) exit;;
            #* ) echo "Please answer y or n.";;
        #esac
    #done
}

#
# Install from scratch
#

function installAnew() {
    local projects
    projects=($*)
    for project in $projects; do
        (
            cd $wd &&
            git clone --quiet git://github.com/D-Programming-Language/$project.git &&
            touch $tempdir/$project
        ) &
    done
    wait

    for project in $projects; do
        if [ ! -f $tempdir/$project ]; then
            echo "Getting $project failed." >&2
            rm -rf $tempdir
            exit 1
        fi
        if [[ ! -z $tag &&
                    ($project = dmd || $project = druntime || $project = phobos) ]]; then
                ( cd $wd/$project && git checkout v$tag )
        fi
    done
}

#
# Freshen existing stuff
#

function update() {
    echo "Updating projects in $wd..."

    function update_project() {
        local project=$1
        local gitproject="git://github.com/D-Programming-Language/$project.git"
        if ! ( cd "$wd/$project" && \
            git checkout master && \
            git pull --ff-only $gitproject master && \
            git pull $gitproject master --tags && \
            git fetch $gitproject && \
            git fetch --tags $gitproject) 2>$tempdir/$project.log
        then
            echo "Failure updating $wd/$project." >>$tempdir/errors
            exit 1
        fi
    }

    for project in $toUpdate; do
        update_project $project &
    done
    wait

    if [ -f $tempdir/errors ]; then
        cat $tempdir/*.log >&2
        exit 1
    fi
}

function makeWorld() {
# First make dmd
    if [[ ! -f "$host_dc" ]]; then
        cd "$wd/dmd/src" &&
        $makecmd -f posix.mak clean AUTO_BOOTSTRAP=1 MODEL=$model &&
        $makecmd -f posix.mak -j $parallel AUTO_BOOTSTRAP=1 MODEL=$model
    else
        cd "$wd/dmd/src" &&
        $makecmd -f posix.mak clean HOST_DC=$host_dc MODEL=$model &&
        $makecmd -f posix.mak -j $parallel HOST_DC=$host_dc MODEL=$model
    fi

# Update the running dmd version
    if [[ ! -z $install ]]; then
        local old=$(which dmd)
        if [ -f "$old" ]; then
            echo "Copying $target_dc over $old"
            [ ! -w "$old" ] && local sudo="sudo"
            $sudo cp "$target_dc" "$old"
        fi
    fi

# Then make druntime
    (
        cd "$wd/druntime" &&
        $makecmd -f posix.mak clean DMD="$target_dc" MODEL=$model &&
        $makecmd -f posix.mak -j $parallel DMD="$target_dc" MODEL=$model
    )

# Then make phobos
    (
        cd "$wd/phobos" &&
        $makecmd -f posix.mak clean DMD="$target_dc" MODEL=$model &&
        $makecmd -f posix.mak -j $parallel DMD="$target_dc" MODEL=$model
    )
}

# main
handleCmdLine $*
confirmChoices
installAnew $toInstall
update $toUpdate
makeWorld
