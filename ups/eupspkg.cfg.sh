# EupsPkg config file. Sourced by 'eupspkg'

MAKE_INSTALL_TARGETS="-j1 install"

config(){
	clean_old_install
}

build() {
	./configure --prefix $PREFIX --disable-fortran --enable-shared $1
	make && make -j1 install
}

install()
{
	build --enable-single
	install_ups
}
