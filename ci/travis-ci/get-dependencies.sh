#!/usr/bin/env sh

# Exit on errors
set -e

cd "${TRAVIS_BUILD_DIR}"

. ci/travis-ci/defs.sh

print_headline "Getting dependencies for building for ${TARGET_OS}/qt${QT} on ${TRAVIS_OS_NAME}"

if [ "${TARGET_OS}" = "linux" -a "${TRAVIS_OS_NAME}" = "linux" ]; then
	print_info "Nothing to do"
elif [ "${TARGET_OS}" = "win" -a "${TRAVIS_OS_NAME}" = "linux" ]; then
	if [ "${QT}" -ne 5 ]; then
		print_error "Unsupported Qt version '${QT}'"
		exit 1
	fi

	MXEDIR="/usr/lib/mxe"
	MXETARGET="i686-w64-mingw32.static"

	print_info "Make MXE directory writable"
	echo_and_run "sudo chmod -R a+w ${MXEDIR}"

	echo "MXEDIR=\"${MXEDIR}\"" >> ci/travis-ci/defs.sh
	echo "MXETARGET=\"${MXETARGET}\"" >> ci/travis-ci/defs.sh

	print_info "Exporting CC = ${MXETARGET}-gcc"
	export CC="${MXETARGET}-gcc"
	print_info "Exporting CXX = ${MXETARGET}-g++"
	export CXX="${MXETARGET}-g++"

	JOBS=$(grep '^processor' /proc/cpuinfo | wc -l)

	cd ci/travis-ci/mxe

	print_info "Building poppler (using ${JOBS} jobs)"
	env PATH="${MXEDIR}/usr/bin:${MXEDIR}/usr/${MXETARGET}/qt/bin:$PATH" PREFIX="${MXEDIR}/usr" TARGET="${MXETARGET}" JOBS="$JOBS" MXE_CONFIGURE_OPTS="--host='${MXETARGET}' --build='$(${MXEDIR}/ext/config.guess)' --prefix='${MXEDIR}/usr/${MXETARGET}' --enable-static --disable-shared ac_cv_prog_HAVE_DOXYGEN='false'" TEST_FILE="poppler-test.cxx" make -f build-poppler-mxe.mk

elif [ "${TARGET_OS}" = "osx" -a "${TRAVIS_OS_NAME}" = "osx" ]; then
	print_info "Updating homebrew"
	brew update > brew_update.log || { print_error "Updating homebrew failed"; cat brew_update.log; exit 1; }
	if [ "${QT}" -eq 5 ]; then
		print_info "Brewing packages: poppler hunspell lua"
		# Travis-CI comes with python@2 preinstalled; poppler depends on
		# gobject-introspection, which depends on python, which
		# conflicts with the preinstalled version; so we unlink the
		# pre-installed version first
		brew unlink python@2
		# Qt5 is already pre-installed (and will be upgraded to the newest
		# version automatically if necessary when poppler is upgraded)
#		brew install qt5
		# poppler is installed by default, but we need to upgrade it to our own,
		# patched version
		brew upgrade "${TRAVIS_BUILD_DIR}/CMake/packaging/mac/poppler.rb"
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
	echo_and_run "./qt-installer.exe --script ci/travis-ci/win32/qt-install.qs"

	echo_and_run "ls /c/"
	echo_and_run "ls /c/Qt/"
else
	print_error "Unsupported host/target combination '${TRAVIS_OS_NAME}/${TARGET_OS}'"
	exit 1
fi

cd "${TRAVIS_BUILD_DIR}"

print_info "Successfully set up dependencies"
