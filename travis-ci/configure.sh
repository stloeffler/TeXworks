#!/usr/bin/env sh

# Exit on errors
set -e

cd "${TRAVIS_BUILD_DIR}"

. travis-ci/defs.sh

print_headline "Configuring for building for ${TARGET_OS}/qt${QT} on ${TRAVIS_OS_NAME}"

./getGitRevInfo.sh

export BUILDDIR="${TRAVIS_BUILD_DIR}/build-${TRAVIS_OS_NAME}-${TARGET_OS}-qt${QT}"

print_info "Making build directory '${BUILDDIR}'"
mkdir "${BUILDDIR}"
cd "${BUILDDIR}"

if [ "${TARGET_OS}" = "linux" -a "${TRAVIS_OS_NAME}" = "linux" ]; then
	print_info "Running CMake"
	echo_and_run "cmake .. -DTW_BUILD_ID='travis-ci' -DCMAKE_INSTALL_PREFIX='/usr' -DDESIRED_QT_VERSION=\"$QT\""
elif [ "${TARGET_OS}" = "win" -a "${TRAVIS_OS_NAME}" = "linux" ]; then
	print_info "Running CMake"
	echo_and_run "cmake .. \
		-DCMAKE_BUILD_TYPE='Release' \
		-DTW_BUILD_ID='travis-ci' \
		-DDESIRED_QT_VERSION=5 \
		-DCMAKE_TOOLCHAIN_FILE='${MXEDIR}/usr/${MXETARGET}/share/cmake/mxe-conf.cmake' \
		-DCMAKE_PREFIX_PATH='${MXEDIR}/usr/${MXETARGET}/qt5/lib/cmake' \
		-DQTPDF_ADDITIONAL_LIBS='freetype;harfbuzz;glib-2.0;intl;iconv;ws2_32;winmm;tiff;jpeg;png;lcms;lzma;bz2' \
		-DTEXWORKS_ADDITIONAL_LIBS='pcre16;opengl32;imm32;shlwapi'"
elif [ "${TARGET_OS}" = "osx" -a "${TRAVIS_OS_NAME}" = "osx" ]; then
	if [ "${QT}" -eq 4 ]; then
		print_info "Running CMake"
		echo_and_run "cmake .. -DTW_BUILD_ID='travis-ci' -DDESIRED_QT_VERSION=\"$QT\" -DCMAKE_OSX_SYSROOT=macosx"
	elif [ "${QT}" -eq 5 ]; then
		print_info "Running CMake"
		echo_and_run "cmake .. -DTW_BUILD_ID='travis-ci' -DDESIRED_QT_VERSION=\"$QT\" -DCMAKE_OSX_SYSROOT=macosx -DCMAKE_PREFIX_PATH=\"/usr/local/opt/qt5\""
	else
		print_error "Unsupported Qt version '${QT}'"
		exit 1
	fi
	# -DCMAKE_OSX_DEPLOYMENT_TARGET='10.6'
else
	print_error "Unsupported host/target combination '${TRAVIS_OS_NAME}/${TARGET_OS}'"
	exit 1
fi

print_info "Successfully configured build"

