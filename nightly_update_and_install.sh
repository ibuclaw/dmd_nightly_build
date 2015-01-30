#!/usr/local/bin/bash

function finish {
  echo "End  :" `date` >> last_build
  echo "End  :" `date` >> build_history
}

cd /usr/local/dlang.org/asm/dmd_nightly_build

echo "Start:" `date` > last_build
echo "Start:" `date` >> build_history

./update.sh > update.sh.log 2>&1
if [ $? -ne 0 ]; then
  echo "Error: update.sh returned non-zero exit code, check update.sh.log" >> last_build
  echo "Error: update.sh returned non-zero exit code, check update.sh.log" >> build_history
  finish
  exit 1
fi

./install.sh > install.sh.log 2>&1
if [ $? -ne 0 ]; then
  echo "Error: install.sh returned non-zero exit code, check install.sh.log" >> last_build
  echo "Error: install.sh returned non-zero exit code, check install.sh.log" >> build_history
  finish
  exit 1
fi

./reload_server.sh > reload_server.sh.log 2>&1
finish
