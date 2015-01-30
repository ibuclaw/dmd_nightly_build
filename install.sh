
# This script copies the newly built dmd to a staged directory, then to the final target

# VARIABLES
export STAGE=./stage
export TARGET=../dmd_nightly

# Create directories
rm -rf ${STAGE}
mkdir ${STAGE}
mkdir ${STAGE}
mkdir ${STAGE}/freebsd
mkdir ${STAGE}/freebsd/bin64
mkdir ${STAGE}/freebsd/lib64
mkdir ${STAGE}/src
mkdir ${STAGE}/src/druntime
mkdir ${STAGE}/src/phobos

# Copy binaries
cp -v dmd/src/dmd ${STAGE}/freebsd/bin64
cp -v dmd/ini/freebsd/bin64/dmd.conf ${STAGE}/freebsd/bin64
cp -v phobos/generated/freebsd/release/64/libphobos2.a ${STAGE}/freebsd/lib64

# Copy druntime source
cp -r -v druntime/import ${STAGE}/src/druntime

# Copy phobos source
cp -r -v phobos/std ${STAGE}/src/phobos
cp -r -v phobos/etc ${STAGE}/src/phobos

# Remove target and move stage to target
rm -rf ${TARGET}
mv ${STAGE} ${TARGET}

# Remove stage
rm -rf ${STAGE}
