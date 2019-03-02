#!/usr/bin/env sh

# Exit on errors
set -e

cd "${TRAVIS_BUILD_DIR}"

. travis-ci/defs.sh

print_headline "Getting dependencies for building for ${TARGET_OS}/qt${QT} on ${TRAVIS_OS_NAME}"

if [ "${TARGET_OS}" = "linux" -a "${TRAVIS_OS_NAME}" = "linux" ]; then
	print_info "Nothing to do"
elif [ "${TARGET_OS}" = "win" -a "${TRAVIS_OS_NAME}" = "linux" ]; then
	if [ "${QT}" -ne 5 ]; then
		print_error "Unsupported Qt version '${QT}'"
		exit 1
	fi

	MXEDIR="/opt/mxe"
	MXETARGET="i686-w64-mingw32.static"

	echo "MXEDIR=\"${MXEDIR}\"" >> travis-ci/defs.sh
	echo "MXETARGET=\"${MXETARGET}\"" >> travis-ci/defs.sh

	print_info "Exporting CC = ${MXETARGET}-gcc"
	export CC="${MXETARGET}-gcc"
	print_info "Exporting CXX = ${MXETARGET}-g++"
	export CXX="${MXETARGET}-g++"

	JOBS=$(grep '^processor' /proc/cpuinfo | wc -l)

#	print_info "Make MXE writable"
#	sudo chmod -R a+w "${MXEDIR}"

	print_info "Fetching MXE from docker"
#	echo_and_run "docker pull stloeffler/mxe-tw"
	echo_and_run "docker create --name mxe stloeffler/mxe-tw"
	echo_and_run "docker cp mxe:${MXEDIR} ${MXEDIR}"


#	echo_and_run "cat \"${MXEDIR}/usr/i686-w64-mingw32.static/lib/libharfbuzz.la\""
#
#	print_info "Fixing libharfbuzz.la"
#	echo_and_run "sed -ie 's#libfreetype.la#libfreetype.la -lharfbuzz_too#g' \"${MXEDIR}/usr/i686-w64-mingw32.static/lib/libharfbuzz.la\""

	# FIXME: Ugly hack
	cd "${MXEDIR}"
	make libwebp
	cd "${TRAVIS_BUILD_DIR}"


	cd travis-ci/mxe

	print_info "Building hunspell (using ${JOBS} jobs)"
	env PATH="${MXEDIR}/usr/bin:${MXEDIR}/usr/${MXETARGET}/qt5/bin:$PATH" PREFIX="${MXEDIR}/usr" TARGET="${MXETARGET}" JOBS="$JOBS" MXE_CONFIGURE_OPTS="--host='${MXETARGET}' --build='$(${MXEDIR}/ext/config.guess)' --prefix='${MXEDIR}/usr/${MXETARGET}' --enable-static --disable-shared" TEST_FILE="hunspell-test.cpp" make -f build-hunspell-mxe.mk

	print_info "Building poppler (using ${JOBS} jobs)"
	env PATH="${MXEDIR}/usr/bin:${MXEDIR}/usr/${MXETARGET}/qt5/bin:$PATH" PREFIX="${MXEDIR}/usr" TARGET="${MXETARGET}" JOBS="$JOBS" MXE_CONFIGURE_OPTS="--host='${MXETARGET}' --build='$(${MXEDIR}/ext/config.guess)' --prefix='${MXEDIR}/usr/${MXETARGET}' --enable-static --disable-shared ac_cv_prog_HAVE_DOXYGEN='false' --disable-doxygen --enable-poppler-qt5 --disable-poppler-qt4" TEST_FILE="poppler-test.cxx" make -f build-poppler-mxe.mk

elif [ "${TARGET_OS}" = "osx" -a "${TRAVIS_OS_NAME}" = "osx" ]; then
	print_info "Updating homebrew"
	brew update > brew_update.log || { print_error "Updating homebrew failed"; cat brew_update.log; exit 1; }
	if [ $QT -eq 5 ]; then
		print_info "Brewing packages: qt5 poppler hunspell lua"
		# Travis-CI comes with python preinstalled; poppler depends on
		# gobject-introspection, which depends on python@2, which
		# conflicts with the preinstalled version; so we unlink the
		# pre-installed version first
		brew unlink python
		brew install qt5
		brew install "${TRAVIS_BUILD_DIR}/CMake/packaging/mac/poppler.rb"
	else
		print_error "Unsupported Qt version '${QT}'"
		exit 1
	fi
	brew install hunspell
	brew install lua;
elif [ "${TARGET_OS}" = "win" -a "${TRAVIS_OS_NAME}" = "windows" ]; then
	echo_and_run "pwd"
	echo_and_run "ls"
	ls /c/
	print_info "Installing Qt5"
	echo_and_run "wget --no-verbose -O qt-installer.exe http://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe"
	echo_and_run "ls"
	echo_and_run "./qt-installer.exe --script travis-ci/win32/qt-install.qs"

	echo_and_run "ls /c/"
	echo_and_run "ls /c/Qt/"
else
	print_error "Unsupported host/target combination '${TRAVIS_OS_NAME}/${TARGET_OS}'"
	exit 1
fi

cd "${TRAVIS_BUILD_DIR}"

print_info "Successfully set up dependencies"
