# EupsPkg config file. Sourced by 'eupspkg'


prep(){
	default_prep
	pwd
	cd ../
	pwd
	cp -r source sp #single precision
	cp -r source dp #double precision
	rm -r source/*
	mv sp source/
	mv dp source/
	cp -r source/dp/ups source/
	cp source/dp/fftw.pc.in source/
}

config(){
	cd sp
	./configure --prefix $PREFIX --disable-fortran --enable-shared --enable-single
	cd ../dp
	./configure --prefix $PREFIX --disable-fortran --enable-shared
}


build() {
	cd sp
	make
	cd ../dp
	make
}

install()
{
	clean_old_install
	cd sp
	make install
	cd ../dp
	make install
	install_ups
}
