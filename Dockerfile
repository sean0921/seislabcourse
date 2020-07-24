FROM debian:buster
MAINTAINER Sean Ho <sean.li.shin.ho@gmail.com>

COPY source/sac-101.6a-source.tar.gz /srv/source/sac-101.6a-source.tar.gz
COPY config/users.txt /srv/config/users.txt
COPY config/locale.gen /etc/locale.gen

WORKDIR /build
RUN mkdir /var/run/sshd \
    && newusers /srv/config/users.txt \
    && ( echo 'deb http://deb.debian.org/debian buster-backports main' | tee -a /etc/apt/sources.list ) \
    && sed -i 's/deb\.debian\.org/debian\.ccns\.ncku\.edu\.tw/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get -y -t buster-backports upgrade \
    && apt-get install -t buster-backports -y gmt \
                                              gmt-gshhg \
                                              gmt-dcw \
                                              build-essential \
                                              libx11-dev \
                                              libncurses-dev \
                                              libreadline-dev \
                                              fakeroot \
                                              dpkg-dev \
                                              devscripts \
                                              debhelper \
                                              git \
                                              openssh-server \
                                              sudo \
                                              csh \
                                              bash-doc \
                                              vim \
                                              locales \
                                              apt-utils \
    && sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/g' /etc/ssh/sshd_config \
    && usermod -G sudo admin \
    && git clone https://github.com/sean0921/sac_debian_packager.git sacbuild \
    && cp /srv/source/sac-101.6a-source.tar.gz sacbuild/ \
    && cd sacbuild \
    && bash build.bash -v \
    && apt-get install -y ./sac-iris-*.deb \
    && cd .. \
    && git clone -b master --single-branch https://salsa.debian.org/debian-gis-team/gmt.git gmt-build/gmt-debian \
    && cd gmt-build/gmt-debian \
    && mk-build-deps debian/control \
    && apt-get install -t buster-backports -y ./gmt-build-deps_*.deb \
    && debuild -b -rfakeroot -us -uc \
    && cd .. \
    && apt-get install -t buster-backports -y ./gmt_*_amd64.deb \
                                              ./libgmt6_*_amd64.deb \
                                              ./gmt-common_*_all.deb \
                                              ./libgmt-dev_*_amd64.deb \
    && apt-get remove -y gmt-build-deps \
                         build-essential \
                         libx11-dev \
                         libncurses-dev \
                         libreadline-dev \
                         fakeroot \
                         dpkg-dev \
                         devscripts \
                         debhelper \
    && apt-get autoremove -y \
    && rm -vrf /build/*

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
