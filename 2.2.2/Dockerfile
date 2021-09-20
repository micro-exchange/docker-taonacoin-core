# Build stage for BerkeleyDB
FROM ubuntu as berkeleydb

RUN apt-get update

RUN apt-get install -y wget
RUN apt-get install -y build-essential

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN update-ca-certificates -f
RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

# Build stage for Taonacoin Core
FROM ubuntu as taonacoin-core

RUN apt-get update

RUN apt-get install -y git
RUN apt-get install -y build-essential
RUN apt-get install -y libzmq3-dev
RUN apt-get install -y autotools-dev
RUN apt-get install -y automake
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pkg-config
RUN apt-get install -y libtool
RUN apt-get install -y libboost-all-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y libevent-dev
RUN apt-get install -y bsdmainutils
RUN apt-get install -y python3

COPY --from=berkeleydb /opt /opt

ENV TAONACOIN_VERSION=2.2.2
ENV TAONACOIN_PREFIX=/opt/taonacoin-${TAONACOIN_VERSION}

RUN git clone https://github.com/TaonaProject/Taonacoin.git /taonacoin-${TAONACOIN_VERSION} \
    && cd /taonacoin-${TAONACOIN_VERSION} \
    && git checkout 7934224729197b3d6d8e43ae09fe6e0fc090ef9e

WORKDIR /taonacoin-${TAONACOIN_VERSION}

# RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
# RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
# RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh

ADD ./httpserver.patch /taonacoin-${TAONACOIN_VERSION}/src/httpserver.patch 
RUN cd /taonacoin-${TAONACOIN_VERSION}/src && patch < httpserver.patch

RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    --prefix=${TAONACOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon
RUN make -j4
RUN make install
RUN strip ${TAONACOIN_PREFIX}/bin/taona-cli
# RUN strip ${TAONACOIN_PREFIX}/bin/taonacoin-tx
RUN strip ${TAONACOIN_PREFIX}/bin/taonad
# RUN strip ${TAONACOIN_PREFIX}/lib/libtaonacoinconsensus.a
# RUN strip ${TAONACOIN_PREFIX}/lib/libtaonacoinconsensus.so.0.0.0

# Build stage for compiled artifacts
FROM ubuntu

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN apt-get install -y libzmq3-dev
RUN apt-get install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
RUN apt-get install -y libevent-dev 
RUN apt-get install -y curl

RUN useradd -r taonacoin

ENV TAONACOIN_DATA=/home/taonacoin/.taonacoin
ENV TAONACOIN_VERSION=2.2.2
ENV TAONACOIN_PREFIX=/opt/taonacoin-${TAONACOIN_VERSION}
ENV PATH=${TAONACOIN_PREFIX}/bin:$PATH

COPY --from=taonacoin-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/taonacoin/.taonacoin"]

EXPOSE 8332 8333 18332 18333 18444

ENTRYPOINT ["/entrypoint.sh"]

RUN taonad -version | grep "Taona Core Daemon version v${TAONACOIN_VERSION}"

CMD ["taonad"]
