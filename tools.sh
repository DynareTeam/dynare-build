# (C) DynareTeam 2017
#
# This file is part of dynare-build project. Sources are available at:
#
#     https://gitlab.com/DynareTeam/dynare-build.git
#
# Dynare-build is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Dynare-build is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

number_of_subfolders () {
    # Returns the number of subfolders in a directory
    #
    # INPUTS
    # [1] Path to the directory.
    #
    # OUTPUTS
    # [1] Number of folders in the directory.
    #
    # Note that the hidden directories are not accounted for.
    echo $(find $1 -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type d | wc -l)
}

number_of_files_with_given_extension () {
    # Returns the number of files with given extension in a directory
    #
    # INPUTS
    # [1] Path to the directory.
    # [2] Extension.
    #
    # OUTPUTS
    # [1] Number of files with $2 extension in the directory.
    #
    # Note that the hidden files are not accounted for.
    echo $(find $1 -mindepth 1 -maxdepth 1 -iname "*.$2" -not -path '*/\.*' -type f | wc -l)
}

number_of_folders () {
    # Returns the number of folders in a directory
    #
    # INPUTS
    # [1] Path to the directory.
    #
    # OUTPUTS
    # [1] Number of files with $2 extension in the directory.
    #
    # Note that the hidden folders are not accounted for.
    echo $(find $1 -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type d | wc -l)
}

delete_oldest_files_with_given_extension () {
    # Deletes the oldest files with given extension in a directory, keeping the most recent MAX_NUMBER_OF_FILES files.
    #
    # INPUTS
    # [1] Path to the directory.
    # [2] Extension.
    # [3] Number of files to be kept (value of MAX_NUMBER_OF_FILES).
    #
    # OUTPUTS
    # None
    #
    # Note that if the number of files with given extension is less than MAX_NUMBER_OF_FILES, then the function will not
    # do anything.
    local n
    n=$(number_of_files_with_given_extension $1 $2)
    if [ $n -gt $3 ]; then
	local number_of_files_to_be_deleted oldest_files
	number_of_files_to_be_deleted=$(($n-$3))
	oldest_files=$(ls -t1 $1/*.$2 | tail -n $number_of_files_to_be_deleted)
	tput bold; tput setaf 1; echo "I am deleting:"; tput sgr0
	tput setaf 1; echo $oldest_files ; tput sgr0
	rm $oldest_files
    fi
}

delete_oldest_folders () {
    # Deletes the oldest subfolders in a directory, keeping the most recent MAX_NUMBER_OF_FOLDERS folders.
    #
    # INPUTS
    # [1] Path to the directory.
    # [2] Number of folders to be kept (value of MAX_NUMBER_OF_FOLDERS).
    #
    # OUTPUTS
    # None
    #
    # Note that if the number of subfolders is less than MAX_NUMBER_OF_FOLDERS, then the function will not
    # do anything.
    local n
    n=$(number_of_folders $1)
    if [ $n -gt $2 ]; then
	local number_of_folders_to_be_deleted oldest_folders
	number_of_folders_to_be_deleted=$(($n-$2))
	oldest_folders=$(ls -td1 $1/*/ | tail -n $number_of_folders_to_be_deleted)
	tput bold; tput setaf 1; echo "I am deleting:"; tput sgr0
	tput setaf 1; echo $oldest_folders; tput sgr0
	rm -rf $oldest_folders
	echo `pwd`
    fi
}

movedir () {
    # Moves a directory from $1 to $2. If $2 already exist, its content is updated.
    #
    # INPUTS
    # [1] Directory to be moved.
    # [2] New dirtectory path.
    #
    # OUTPUTS
    # None
    if [ ! -d $1 ]; then
	echo "Directory $1 not found!"
	exit 1
    fi
    if [ ! -d $2 ]; then
	mv $1 $2
    else
	rsync -a $1 $2
	rm -rf $1
    fi
}

build_windows_matlab_mex_32 () {
    # Create Windows 32-bit DLL binaries for MATLAB R2008b
    mkdir -p $TMP_DIRECTORY/$VERSION-matlab-win32
    cp -r $THIS_BUILD_DIRECTORY/* $TMP_DIRECTORY/$VERSION-matlab-win32
    cd $TMP_DIRECTORY/$VERSION-matlab-win32/mex/build/matlab
    ./configure --host=i686-w64-mingw32 \
		--with-boost=$LIB32/Boost \
		--with-gsl=$LIB32/Gsl \
		--with-matio=$LIB32/matIO \
		--with-slicot=$LIB32/Slicot/without-underscore \
		--with-matlab=$LIB32/matlab/R2008b \
		MATLAB_VERSION=R2008b \
		MEXEXT=mexw32 \
		PACKAGE_VERSION=$DYNARE_VERSION \
		PACKAGE_STRING="dynare $VERSION"
    make -j$NTHREADS all
    cd $TMP_DIRECTORY/$VERSION-matlab-win32/
    i686-w64-mingw32-strip mex/matlab/*.mexw32
    mkdir -p mex/matlab/win32-7.5-8.6
    mv mex/matlab/*.mexw32 mex/matlab/win32-7.5-8.6
    if [ $NASTY_FIX_FOR_K_ORDER -eq 1 ]; then
	mv $ROOT_DIRECTORY/oldies/matlab-dll/4.4.3/win32-7.5-8.3/k_order_perturbation.mexw32 mex/matlab/win32-7.5-8.6
	mv $ROOT_DIRECTORY/oldies/matlab-dll/4.4.3/win32-7.5-8.3/dynare_simul_.mexw32 mex/matlab/win32-7.5-8.6
    fi
    movedir mex/matlab/win32-7.5-8.6 $THIS_BUILD_DIRECTORY/mex/matlab
    cd $ROOT_DIRECTORY
    rm -rf $TMP_DIRECTORY/$VERSION-matlab-win32
}

build_windows_matlab_mex_64_a () {
    # Create Windows 64-bit DLL binaries for MATLAB R2008b
    mkdir -p $TMP_DIRECTORY/$VERSION-matlab-win64-a
    cp -r $THIS_BUILD_DIRECTORY/* $TMP_DIRECTORY/$VERSION-matlab-win64-a
    cd $TMP_DIRECTORY/$VERSION-matlab-win64-a/mex/build/matlab
    ./configure --host=x86_64-w64-mingw32 \
		--with-boost=$LIB64/Boost \
		--with-gsl=$LIB64/Gsl \
		--with-matio=$LIB64/matIO \
		--with-slicot=$LIB64/Slicot/without-underscore \
		--with-matlab=$LIB64/matlab/R2008b \
		MATLAB_VERSION=R2008b \
		MEXEXT=mexw64 \
		PACKAGE_VERSION=$DYNARE_VERSION \
		PACKAGE_STRING="dynare $VERSION"
    make -j$NTHREADS all
    cd $TMP_DIRECTORY/$VERSION-matlab-win64-a/
    x86_64-w64-mingw32-strip mex/matlab/*.mexw64
    mkdir -p mex/matlab/win64-7.5-7.7
    mv mex/matlab/*.mexw64 mex/matlab/win64-7.5-7.7
    if [ $NASTY_FIX_FOR_K_ORDER -eq 1 ]; then
	mv $ROOT_DIRECTORY/oldies/matlab-dll/4.4.3/win64-7.5-7.7/k_order_perturbation.mexw64 mex/matlab/win64-7.5-7.7
	mv $ROOT_DIRECTORY/oldies/matlab-dll/4.4.3/win64-7.5-7.7/dynare_simul_.mexw64 mex/matlab/win64-7.5-7.7
    fi
    movedir mex/matlab/win64-7.5-7.7 $THIS_BUILD_DIRECTORY/mex/matlab
    cd $ROOT_DIRECTORY
    rm -rf $TMP_DIRECTORY/$VERSION-matlab-win64-a
}

build_windows_matlab_mex_64_b () {
    # Create Windows 64-bit DLL binaries for MATLAB R2008b
    mkdir -p $TMP_DIRECTORY/$VERSION-matlab-win64-b
    cp -r $THIS_BUILD_DIRECTORY/* $TMP_DIRECTORY/$VERSION-matlab-win64-b
    cd $TMP_DIRECTORY/$VERSION-matlab-win64-b/mex/build/matlab
    ./configure --host=x86_64-w64-mingw32 \
		--with-boost=$LIB64/Boost \
		--with-gsl=$LIB64/Gsl \
		--with-matio=$LIB64/matIO \
		--with-slicot=$LIB64/Slicot/without-underscore \
		--with-matlab=$LIB64/matlab/R2009a \
		MATLAB_VERSION=R2009a \
		MEXEXT=mexw64 \
		PACKAGE_VERSION=$DYNARE_VERSION \
		PACKAGE_STRING="dynare $VERSION"
    make -j$NTHREADS all
    cd $TMP_DIRECTORY/$VERSION-matlab-win64-b/
    x86_64-w64-mingw32-strip mex/matlab/*.mexw64
    mkdir -p mex/matlab/win64-7.8-9.2
    mv mex/matlab/*.mexw64 mex/matlab/win64-7.8-9.2
    if [ $NASTY_FIX_FOR_K_ORDER -eq 1 ]; then
	mv $ROOT_DIRECTORY/oldies/matlab-dll/4.4.3/win64-7.8-8.3/k_order_perturbation.mexw64 mex/matlab/win64-7.8-9.2
	mv $ROOT_DIRECTORY/oldies/matlab-dll/4.4.3/win64-7.8-8.3/dynare_simul_.mexw64 mex/matlab/win64-7.8-9.2
    fi
    movedir mex/matlab/win64-7.8-9.2 $THIS_BUILD_DIRECTORY/mex/matlab
    cd $ROOT_DIRECTORY
    rm -r $TMP_DIRECTORY/$VERSION-matlab-win64-b
}

build_windows_octave_mex_32 () {
    # Create Windows DLL binaries for Octave/MinGW (32bit)
    mkdir -p $TMP_DIRECTORY/$VERSION-octave-32
    cp -r $THIS_BUILD_DIRECTORY/* $TMP_DIRECTORY/$VERSION-octave-32
    cd $TMP_DIRECTORY/$VERSION-octave-32/mex/build/octave
    ./configure --host=i686-w64-mingw32 MKOCTFILE=$LIB32/mkoctfile --with-boost=$LIB32/Boost --with-gsl=$LIB32/Gsl --with-matio=$LIB32/matIO --with-slicot=$LIB32/Slicot/with-underscore PACKAGE_VERSION=$DYNARE_VERSION PACKAGE_STRING="dynare $VERSION"
    make -j$NTHREADS all
    cd $TMP_DIRECTORY/$VERSION-octave-32/
    rm -rf mex/octave/octave
    i686-w64-mingw32-strip mex/octave/*.mex mex/octave/*.oct
    mkdir -p $THIS_BUILD_DIRECTORY/mex/octave32
    mv mex/octave/* $THIS_BUILD_DIRECTORY/mex/octave32
    cd $ROOT_DIRECTORY
    rm -rf $TMP_DIRECTORY/$VERSION-octave-32
}

build_windows_octave_mex_64 () {
    # Create Windows DLL binaries for Octave/MinGW (64bit)
    mkdir -p $TMP_DIRECTORY/$VERSION-octave-64
    cp -r $THIS_BUILD_DIRECTORY/* $TMP_DIRECTORY/$VERSION-octave-64
    cd $TMP_DIRECTORY/$VERSION-octave-64/mex/build/octave
    ./configure --host=x86_64-w64-mingw32 MKOCTFILE=$LIB64/mkoctfile --with-boost=$LIB64/Boost --with-gsl=$LIB64/Gsl --with-matio=$LIB64/matIO --with-slicot=$LIB64/Slicot/with-underscore PACKAGE_VERSION=$DYNARE_VERSION PACKAGE_STRING="$VERSION"
    make -j$NTHREADS all
    cd $TMP_DIRECTORY/$VERSION-octave-64/
    rm -rf mex/octave/octave
    x86_64-w64-mingw32-strip mex/octave/*.mex mex/octave/*.oct
    mv mex/octave/* $THIS_BUILD_DIRECTORY/mex/octave
    cd $ROOT_DIRECTORY
    rm -rf $TMP_DIRECTORY/$VERSION-octave-64
}

build_internal_documentation () {
    ./configure --enable-org-export --disable-octave --disable-matlab
    make html
    rm -rf $ROOT_DIRECTORY/dynare-internals
    mkdir -p $ROOT_DIRECTORY/dynare-internals
    mv doc/internals/dynare-internals.html $ROOT_DIRECTORY/dynare-internals/index.html
}

build_m2html_documentation () {
    cd mex/build/matlab
    ./configure --with-matlab=$MATLAB_PATH MATLAB_VERSION=$MATLAB_VERS --with-m2html=$ROOT_DIRECTORY/m2html
    make html
    cd ../../..
    rm -rf $ROOT_DIRECTORY/dynare-matlab-m2html
    mv doc/m2html $ROOT_DIRECTORY/dynare-matlab-m2html
}

create_checksum_files() {
    cd $1
    FILES=`ls -I*.sig -IMD5SUMS -ISHA1SUMS -ISHA256SUMS -ISHA512SUMS`
    md5sum $FILES > MD5SUMS
    sha1sum $FILES > SHA1SUMS
    sha256sum $FILES > SHA256SUMS
    sha512sum $FILES > SHA512SUMS
}
