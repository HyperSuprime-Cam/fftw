# EupsPkg config file. Sourced by 'eupspkg'

#
# Note: FFTW_FUNC_PREFIX and FFTW_LIB_PREFIX environmental variables are
# defined in the .table file
#

# FIXME: This is a workaround for lsstsw nor running setup before eupspkg prep
export FFTW_FUNC_PREFIX="lsst_"
export FFTW_LIB_PREFIX=""

CFLAGS+="-fPIC"

if [[ $OSTYPE = darwin* ]]; then
	LIBEXT=dylib
	LEADING_UNDERSCORE=_
	_rename_libraries() { _rename_libraries_osx; }
else
	LIBEXT=so
	LEADING_UNDERSCORE=
	_rename_libraries() { _rename_libraries_linux; }
fi

prep()
{
	#
	# Clone ourselves into a sp and dp directory (for single and double precision)
	#
	sed 's|\$FFTW_FUNC_PREFIX'"|$FFTW_FUNC_PREFIX|g" patches/lsst_prefix_fftw.patch.template > patches/lsst_prefix_fftw.patch

	default_prep

	rm -rf sp dp

	# Copy everything into a temporary directory outside this one (to
	# avoid infinite recursion with cp), then move it to sp/ and
	# duplicate to dp/
	TMPCOPY=$(mktemp -d -t XXXXX)
	cp -a . "$TMPCOPY/sp"
	rm -rf "$TMPCOPY/sp/"{.git,_eupspkg,upstream,patches,ups,_build.log}
	mv "$TMPCOPY/sp" .
	cp -a sp dp

	# Clean up the local dir (and try to do it relatively safely)
	# by removing only files & directories found in the expanded dir
	ls sp/ | while read FN; do
		rm -rf "$PWD/$FN"
	done
}

config()
{
	( cd sp && ./configure CFLAGS="$CFLAGS" --program-prefix=$FFTW_LIB_PREFIX --prefix $PREFIX --disable-fortran --libdir=$PREFIX/lib --enable-single )
	( cd dp && ./configure CFLAGS="$CFLAGS" --program-prefix=$FFTW_LIB_PREFIX --prefix $PREFIX --disable-fortran --libdir=$PREFIX/lib )
}

build()
{
	( cd sp && make )
	( cd dp && make )
}

_rename_libraries_osx()
{
	(
		cd "$PREFIX/lib"

		# drop symlinks
		rm -f {libfftw3,libfftw3f}.dylib

		# rename static & dynamic libraries
		for NAME in lib*.{dylib,a,la}; do
			mv "$NAME" lib""$FFTW_LIB_PREFIX""${NAME#lib}
		done

		# change install names of dynamic libraries
		for NAME in lib*.dylib; do
			install_name_tool -id $NAME $NAME
		done

		# change the names within libtool .la files
		for NAME in lib*.la; do
			sed -i "" "s|libfftw3|lib${FFTW_LIB_PREFIX}fftw3|g" $NAME
		done
		
		# fixup pkgconfigs
		(
			cd pkgconfig
			for NAME in *.pc; do
				sed -i "" "s|-lfftw3|-l${FFTW_LIB_PREFIX}fftw3|g" $NAME
				mv $NAME ${FFTW_LIB_PREFIX}$NAME
			done
		)

		# re-establish the symlinks
		ln -s lib${FFTW_LIB_PREFIX}fftw3.3.dylib  lib${FFTW_LIB_PREFIX}fftw3.dylib
		ln -s lib${FFTW_LIB_PREFIX}fftw3f.3.dylib lib${FFTW_LIB_PREFIX}fftw3f.dylib

	)

	# fix library names in .cfg files
	sed -i "" "s|\"fftw3\"|\"${FFTW_LIB_PREFIX}fftw3\"|"   "$PREFIX/ups/fftw.cfg"
	sed -i "" "s|\"fftw3f\"|\"${FFTW_LIB_PREFIX}fftw3f\"|" "$PREFIX/ups/fftw.cfg"
}

_rename_libraries_linux()
{
	(
		cd "$PREFIX/lib"

		# drop symlinks
		rm -f {libfftw3,libfftw3f}.so{,.3}

		# rename static & dynamic libraries
		if [[ -f lib${FFTW_LIB_PREFIX}fftw3.so.* ]]; then
			SOGLOB="*.so.*"
		fi
		for NAME in lib*.{a,la} $SOGLOB; do
			mv "$NAME" lib""$FFTW_LIB_PREFIX""${NAME#lib}
		done

		# change the names within libtool .la files
		for NAME in lib*.la; do
			sed -i "s|libfftw3|lib${FFTW_LIB_PREFIX}fftw3|g" $NAME
		done
		
		# fixup pkgconfigs
		(
			cd pkgconfig
			for NAME in *.pc; do
				sed -i "s|-lfftw3|-l${FFTW_LIB_PREFIX}fftw3|g" $NAME
				mv $NAME ${FFTW_LIB_PREFIX}$NAME
			done
		)

		# re-establish the symlinks
		if [[ -f lib${FFTW_LIB_PREFIX}fftw3.so.* ]]; then
			ln -s lib${FFTW_LIB_PREFIX}fftw3.so.*  lib${FFTW_LIB_PREFIX}fftw3.so
			ln -s lib${FFTW_LIB_PREFIX}fftw3.so.*  lib${FFTW_LIB_PREFIX}fftw3.so.3
		fi
		if [[ -f lib${FFTW_LIB_PREFIX}fftw3f.so.* ]]; then
			ln -s lib${FFTW_LIB_PREFIX}fftw3f.so.* lib${FFTW_LIB_PREFIX}fftw3f.so
			ln -s lib${FFTW_LIB_PREFIX}fftw3f.so.* lib${FFTW_LIB_PREFIX}fftw3f.so.3
		fi

		# change install names of dynamic libraries
		if [[ -f lib${FFTW_LIB_PREFIX}fftw3f.so ]]; then
			for NAME in lib*.so.3; do
				patchelf --set-soname $NAME $NAME
			done
		fi

	)

	# fix library names in .cfg files
	sed -i "s|\"fftw3\"|\"${FFTW_LIB_PREFIX}fftw3\"|"   "$PREFIX/ups/fftw.cfg"
	sed -i "s|\"fftw3f\"|\"${FFTW_LIB_PREFIX}fftw3f\"|" "$PREFIX/ups/fftw.cfg"
}

_fixup_headers()
{
	# Generate macro files
	_gen_hdr()
	{
		local DATATYPE=$1

		echo "/* ----------------- */"
		for TYPE in plan_s plan iodim iodim64 write_char_func read_char_func; do
			echo "#define fftw${DATATYPE}_$TYPE ${FFTW_FUNC_PREFIX}fftw${DATATYPE}_${TYPE}"
		done
		echo "/* ----------------- */"

		nm "$PREFIX"/lib/lib${FFTW_LIB_PREFIX}fftw3.a | grep " ${LEADING_UNDERSCORE}${FFTW_FUNC_PREFIX}" | grep -E " (S|T) " | cut -d ' ' -f 3 | \
			while read SYMBOL; do
				FUNC=${SYMBOL#${LEADING_UNDERSCORE}${FFTW_FUNC_PREFIX}fftw_}

				ALIAS=fftw${DATATYPE}_${FUNC}
				SYMBOL=${FFTW_FUNC_PREFIX}${ALIAS}

				echo "#define $ALIAS       $SYMBOL"
			done
	}

	cat >> "$PREFIX/include/fftw3.h" <<-EOF

	#ifndef __FFTW3_LSST_SYMBOL_ALIASES
	#define __FFTW3_LSST_SYMBOL_ALIASES

EOF
	for DATATYPE in "" f l; do
		FN="_${FFTW_FUNC_PREFIX}fftw${DATATYPE}_map.h"

		_gen_hdr "$DATATYPE" > "$PREFIX"/include/$FN
		echo "#include \"$FN\"" >> "$PREFIX/include/fftw3.h"
	done

	cat >> "$PREFIX/include/fftw3.h" <<-EOF

	#endif /* __FFTW3_LSST_SYMBOL_ALIASES */
EOF
}

install()
{
	clean_old_install

	( cd sp && make install )
	( cd dp && make install )

	install_ups

	test ! -z "$FFTW_LIB_PREFIX" && _rename_libraries
	_fixup_headers
}
