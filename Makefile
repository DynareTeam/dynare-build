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

.PHONY: libs build clean-libs install k-order-fix-data

NTHREADS=$(shell echo `nproc --all`)

all: build

libs:
	make -C libs -j$(NTHREADS) build
	make -C libs -j$(NTHREADS) octave-libs
	make -C libs -j$(NTHREADS) install-matlab-files
	make -C libs -j$(NTHREADS) dll

clean-libs:
	make -C libs clean-all

clean: build-clean
	rm -rf signature/source
	rm -f dynare-object-signing.p12.gpg
	rm -f dynare-object-signing.p12
	rm -f snapshot-manager-key.tar.gpg
	rm -f snapshot-manager-key.tar
	rm -rf keys

build-clean:
	rm -f win/*
	rm -f tar/*
	rm -rf builds/*
	rm -rf git/*
	rm -rf git/*
	rm -rf zip/*


cleanall: clean-libs clean
	rm -rf oldies

install:
	./install-packages.sh

build: libs k-order-fix-data
	./build.sh

push: libs k-order-fix-data signature/osslsigncode dynare-object-signing.p12 keys/snapshot-manager_rsa.pub m2html/Contents.m
	./build.sh

signature/osslsigncode:
	rm -rf signature/source
	git clone git://git.code.sf.net/p/osslsigncode/osslsigncode signature/source
	cd signature/source && git reset --hard e72a1937d1a13e87074e4584f012f13e03fc1d64 && ./autogen.sh && ./configure && make 
	mv signature/source/osslsigncode signature/osslsigncode

clean-osslsigncode:
	rm -rf signature/*

dynare-object-signing.p12.gpg:
	wget http://www.dynare.org/dynare-build/dynare-object-signing.p12.gpg

dynare-object-signing.p12: dynare-object-signing.p12.gpg
	./dynare-object-signing.p12.sh

snapshot-manager-key.tar.gpg:
	wget http://www.dynare.org/dynare-build/snapshot-manager-key.tar.gpg

snapshot-manager-key.tar: snapshot-manager-key.tar.gpg
	./snapshot-manager-key.tar.sh

keys/snapshot-manager_rsa.pub: snapshot-manager-key.tar
	mkdir -p keys
	tar -xvf snapshot-manager-key.tar -C keys

m2html.zip:
	wget http://www.artefact.tk/software/matlab/m2html/m2html.zip

m2html/Contents.m: m2html.zip
	mkdir -p m2html
	unzip m2html
	touch m2html/Contents.m

k-order-fix-data: oldies/matlab-dll/4.4.3/archives.tar.xz

oldies/matlab-dll/4.4.3/archives.tar.xz:
	mkdir -p oldies/matlab-dll/4.4.3
	cd oldies/matlab-dll/4.4.3 && wget https://dynare.adjemian.eu/oldies/matlab-dll/4.4.3/archives.tar.xz
	cd oldies/matlab-dll/4.4.3 && tar xJf archives.tar.xz
