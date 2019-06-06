FROM amd64/ubuntu:16.04

## update system and install essential
RUN apt update -y
RUN apt install build-essential vim wget git gfortran mlocate autoconf automake libtool make cmake -y

## install openmpi & openblas
RUN cd /home && wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.2.tar.gz && wget https://github.com/xianyi/OpenBLAS/archive/v0.3.6.tar.gz
RUN tar zxf /home/openmpi-3.1.2.tar.gz -C /home && tar zxf /home/v0.3.6.tar.gz -C /home && mkdir /home/openmpi && mkdir /home/openblas
RUN cd /home/openmpi-3.1.2 && ./configure CXX=g++ CC=gcc --enable-mpi-cxx --enable-mpi-fortran FORTRAN=gfortran --prefix=/home/openmpi && make -j8 && make install -j8
RUN cd /home/OpenBLAS-0.3.6 && export OMP_NUM_THREADS=1
RUN make USE_OPENMP=1 PREFIX=/openblas NUM_THREADS=64 TARGET=NEHALEM LIBNAMESUFFIX=omp USE_THREAD=1
RUN make USE_OPENMP=1 PREFIX=/openblas NUM_THREADS=64 TARGET=NEHALEM LIBNAMESUFFIX=omp USE_THREAD=1 install
ENV PATH=$PATH:/home/openmpi/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/openmpi/lib

## install hpcc
RUN cd /home && wget http://icl.cs.utk.edu/projectsfiles/hpcc/download/hpcc-1.5.0.tar.gz
RUN tar zxf hpcc-1.5.0.tar.gz && cd /home/hpcc-1.5.0/hpl && cp /home/hpcc-1.5.0/hpl/setup/Make.Linux_PII_CBLAS /home/hpcc-1.5.0/hpl/Make.origin
RUN sed -i '70c TOPdir       = /home/hpcc-1.5.0/hpl Make.origin && sed -i '84c MPdir        = /home/openmpi' Make.origin
RUN sed -i '86c MPlib        = $(MPdir)/lib/libmpi.so' Make.origin && sed -i '97c LAlib        = /openblas/lib/libopenblas.a /openblas/lib/libopenblas_omp.a' Make.origin
RUN sed -i '169c CC           = /home/openmpi/bin/mpicc' Make.origin && sed -i '176c LINKER       = /openmpi/bin/mpifort' Make.origin
RUN sed -i '171c CCFLAGS      = $(HPL_DEFS) -fomit-frame-pointer -O3 -funroll-loops -fopenmp' Make.origin && sed -i '159c HPL_OPTS     = ' Make.origin
RUN cd /home/hpcc-1.5.0 && make arch=origin && mv _hpccinf.txt hpccinf.txt && cd /home
