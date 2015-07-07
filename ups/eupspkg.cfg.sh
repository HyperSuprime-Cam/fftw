# EupsPkg config file. Sourced by 'eupspkg'


prep(){
	#Make directories to hold the source for single and double
	#precision libraries
	if [ -d "sp" ]; then
		rm -rf sp
	fi
	if [  -d "dp" ]; then
		rm -rf dp
	fi
	if [ -f "fftw.pc.in" ]; then
		rm fftw.pc.in
	fi
	mkdir sp dp
	default_prep
	#Copy the contents into each directory, excluding the .git directory.
	#eupspkg should use the .git directory from the parent to obtain version information.
	rsync -a --exclude=".git" --exclude="sp" --exclude="dp" ./ sp/ #single precision
	rsync -a --exclude=".git" --exclude="sp" --exclude="dp" ./ dp/ #double precision
	#delete everything but the sp, dp, and required ups
	#files/directories
	rm -rf $(ls |grep -v ^ups* |grep -v fftw.pc.in |grep -v dp |grep\
	-v sp|grep -v ^[.]*$|grep -v _build.log)
}

config(){
	cd sp
	./configure --prefix $PREFIX --disable-fortran --enable-shared --libdir=$PREFIX/lib --enable-single
	cd ../dp
	./configure --prefix $PREFIX --disable-fortran --enable-shared --libdir=$PREFIX/lib
}


build() {
	cd sp
	make
	cd ../dp
	make
	cd ../
	#This next bit is here because lsstsw expects to see a _build.log
	#in the directory. It doesn't seem to be able to handle multiple
	#subdirectoreis with source in it
	if [ -f dp/_build.log ]; then
		cp dp/_build.log ./
	fi
}

install()
{
	clean_old_install
	cd sp
	make install
	cd ../dp
	make install
	cd ../
	install_ups
}
