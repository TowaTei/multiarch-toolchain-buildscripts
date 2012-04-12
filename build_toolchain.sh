###### DO NOT EDIT THIS FILE ######

# ============== GENERIC BUILD STEPS =================
PACKDIR=$BUILD_HOME/packs
BUILD=$BUILD_HOME/$TARGET-gcc-$GCC_VERSION-toolchain-build

# Prepare directories (create if necessary)
mkdir -p $BUILD
mkdir -p $PACKDIR

# Wget the packages if necessary
cd $PACKDIR
for (( n=0; n<${#PACKLITERALS[@]}; n++ )); do
    PACKNAME=${PACKLITERALS[$n]}
    EXTENSION=${PACKEXTENSIONS[$n]}
    if eval "[ ! -e ${PACKNAME}${EXTENSION} ]"; then
        eval "wget ${PACKNAME}_SITE/${PACKNAME}${EXTENSION}"
        if [ $? != 0 ]; then eval "echo Error downloading $PACKNAME"; exit 1; fi
    fi
done

# Unpack if necessary
cd $BUILD
for (( n=0; n<${#PACKLITERALS[@]}; n++ )); do
    PACKNAME=`eval "echo ${PACKLITERALS[$n]}"`
    EXTENSION=${PACKEXTENSIONS[$n]}
    if [ ! -d $PACKNAME ]; then
        if [ $EXTENSION = '.tar.gz' ]; then FL='z'; else FL='j'; fi
        tar -x${FL}f "$PACKDIR/${PACKNAME}${EXTENSION}"
    fi
done

# Make build directories
for (( n=0; n<${#PACKLITERALS[@]}; n++ )); do
    eval "mkdir -p build-${PACKLITERALS[$n]}"
done

# Set-up some environment variables useful during the build process
export LD_LIBRARY_PATH=$PREFIX/lib
export PATH=$PREFIX/bin:$PATH

# configure, make and make install all packs
GCC_BOOTSTRAPPED=no
for taskl in $TASKLITERALS; do
    taski=`eval "echo $taskl"`

    cd build-$taski

    if [ $taski = $GCC -a $GCC_BOOTSTRAPPED = "yes" ]; then # GCC again (post-bootstrap)
        ../$taski/configure --prefix=$PREFIX  $GCC_2_OPT
    else
        if [ ! -e Makefile ]; then # only configure if it wasn't done already (no Makefile)
            ../$taski/configure --prefix=$PREFIX `eval "echo ${taskl}_OPT"`
        fi
    fi
    if [ $? != 0 ]; then echo "Error configuring $taski"; exit 1; fi

    if [ $taski = $GCC ]; then make $THREADS $SILENT_BUILD all-gcc all-target-libgcc
    else make $THREADS $SILENT_BUILD all; fi
    if [ $? != 0 ]; then echo "Error making $taski"; exit 1; fi

    if [ $taski = $GCC ]; then make $THREADS $SILENT_BUILD install-gcc install-target-libgcc
    else make $THREADS $SILENT_BUILD install; fi
    if [ $? != 0 ]; then echo "Error installing $taski"; exit 1; fi
    if [ $taski = $GCC ]; then GCC_BOOTSTRAPPED=yes; fi

    cd ..
done

# Cleanup build directories
cd $BUILD
for (( n=0; n<${#PACKLITERALS[@]}; n++ )); do
    eval "rm -rf build-${PACKLITERALS[$n]}"
    eval "rm -rf ${PACKLITERALS[$n]}"
done
cd ..
rm -rf $BUILD

# info to the user
echo '.'
echo "Beautiful. Now you have your toolchain installed. Everything is under $PREFIX"
echo "To use the toolchain the following paths have to be added to your PATH variable:"
echo '.'
echo "$PREFIX/bin"
echo '.'
echo "Also please define LD_LIBRARY_PATH exactly as follows:"
echo '.'
echo $LD_LIBRARY_PATH
echo '.'
echo "Tip: you can have an alias to setup your variables properly."
echo "for example, you can append the following to your .bash_aliases file:"
echo "\"alias ${TARGET}-tools='export LD_LIBRARY_PATH=$LD_LIBRARY_PATH; export PATH=$PREFIX/bin:\$PATH'\""

exit 0
