FROM amd64/ubuntu:16.04

## update system and install essential
RUN apt update -y
RUN apt install build-essential vim wget git gfortran mlocate autoconf automake libtool make cmake -y

## install openmpi & openblas
WORKDIR /home
RUN wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.2.tar.gz && wget https://github.com/xianyi/OpenBLAS/archive/v0.3.6.tar.gz
RUN tar zxf /home/openmpi-3.1.2.tar.gz -C /home && tar zxf /home/v0.3.6.tar.gz -C /home && mkdir /home/openmpi && mkdir /home/openblas
WORKDIR /home/openmpi-3.1.2
RUN ./configure CXX=g++ CC=gcc --enable-mpi-cxx --enable-mpi-fortran FORTRAN=gfortran --prefix=/home/openmpi && make -j8 && make install -j8
WORKDIR /home/OpenBLAS-0.3.6
ENV OMP_NUM_THREADS=1
RUN make USE_OPENMP=1 PREFIX=/home/openblas NUM_THREADS=64 TARGET=NEHALEM LIBNAMESUFFIX=omp USE_THREAD=1
RUN make USE_OPENMP=1 PREFIX=/home/openblas NUM_THREADS=64 TARGET=NEHALEM LIBNAMESUFFIX=omp USE_THREAD=1 install
ENV PATH $PATH:/home/openmpi/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/home/openmpi/lib

## install hpcc
WORKDIR /home
RUN wget http://icl.cs.utk.edu/projectsfiles/hpcc/download/hpcc-1.5.0.tar.gz
RUN tar zxf /home/hpcc-1.5.0.tar.gz
WORKDIR /home/hpcc-1.5.0/hpl
RUN cp /home/hpcc-1.5.0/hpl/setup/Make.Linux_PII_CBLAS /home/hpcc-1.5.0/hpl/Make.origin
RUN sed -i '70c TOPdir       = /home/hpcc-1.5.0/hpl' Make.origin && sed -i '84c MPdir        = /home/openmpi' Make.origin
RUN sed -i '86c MPlib        = $(MPdir)/lib/libmpi.so' Make.origin && sed -i "97c LAlib        = /home/openblas/lib/libopenblas_omp.a" Make.origin
#RUN ls /home/openblas/lib
RUN sed -i '169c CC           = /home/openmpi/bin/mpicc' Make.origin && sed -i '176c LINKER       = /home/openmpi/bin/mpif90' Make.origin
RUN sed -i '171c CCFLAGS      = $(HPL_DEFS) -fomit-frame-pointer -O3 -funroll-loops -fopenmp' Make.origin && sed -i '159c HPL_OPTS     = ' Make.origin
WORKDIR /home/hpcc-1.5.0
RUN make arch=origin && mv _hpccinf.txt hpccinf.txt
