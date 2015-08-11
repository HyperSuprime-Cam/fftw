# EupsPkg config file. Sourced by 'eupspkg'


prep(){
	default_prep
	#Make directories to hold the source for single and double
	#precision libraries
	if [ -d sp ]; then
		rm -r sp
	fi
	if [  -d dp ]; then
		rm -r dp
	fi
	mkdir sp dp
	#Copy the contents into each directory
	rsync -r --exclude="sp" --exclude="dp" ./ sp/ #single precision
	rsync -r --exclude="sp" --exclude="dp" ./ dp/ #double precision
	#delete everything but the sp, dp, and required ups
	#files/directories
	rm -rf $(ls |grep -v ^ups$ |grep -v fftw.pc.in |grep -v dp |grep\
	-v sp|grep -v ^[.]*$)
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
