# EupsPkg config file. Sourced by 'eupspkg'
CFLAGS+="-fPIC"

prep()
{
	#
	# Clone ourselves into a sp and dp directory (for single and double precision)
	#
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
	( cd sp && ./configure --prefix $PREFIX --disable-fortran --libdir=$PREFIX/lib --enable-single CFLAGS="$CFLAGS" )
	( cd dp && ./configure --prefix $PREFIX --disable-fortran --libdir=$PREFIX/lib CFLAGS="$CFLAGS" )
}

build()
{
	( cd sp && make )
	( cd dp && make )
}

install()
{
	clean_old_install

	( cd sp && make install )
	( cd dp && make install )

	install_ups
}
