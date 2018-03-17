FROM janx/ubuntu-dev
MAINTAINER Raphael Catolino "raphael.catolino@gmail.com"

ENV SHELL /bin/bash
WORKDIR /home/user

USER root
RUN sed -i "s/^# deb-src /deb-src /" /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  bison \
  bzr \
  cmake \
  dialog \
  doxygen \
  extra-cmake-modules \
  flex \
  fontforge \
  git \
  gperf \
  libarchive-dev \
  libattr1-dev \
  libboost-dev \
  libbz2-dev \
  libclang-3.6-dev \
  libclang-dev \
  libegl1-mesa-dev \
  libepoxy-dev \
  libgcrypt20-dev \
  libgif-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgtk-3-dev \
  libjson-perl \
  "libkf5.*-dev" \
  liblmdb-dev \
  libnm-glib-dev \
  libnm-util-dev \
  libpolkit-agent-1-dev \
  libpwquality-dev \
  libqt5x11extras5-dev \
  libvlccore-dev \
  libvlc-dev \
  libwww-perl \
  libxapian-dev \
  "libxcb-*-dev" \
  libxcb-keysyms1-dev \
  libxcb-xkb-dev \
  libxml2-dev \
  libxml-parser-perl \
  libxslt-dev \
  llvm \
  llvm-3.6 \
  modemmanager-dev \
  network-manager-dev \
  oxygen-icon-theme \
  shared-mime-info \
  xserver-xorg-input-synaptics-dev \
  xsltproc

# various utilities
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  qdbus-qt5 \
  xserver-xorg-dev \
  x11-xserver-utils

ADD var.env ./var.env
RUN chown user:user var.env
# Better in .pam_environment maybe ?
RUN echo 'source /home/user/var.env' >> .bashrc
ADD kdesrc-buildrc ./.kdesrc-buildrc
RUN chown user:user .kdesrc-buildrc

RUN echo "deb http://ppa.launchpad.net/beineri/opt-qt591-xenial/ubuntu xenial main" > /etc/apt/sources.list.d/qt.list
RUN echo "deb-src http://ppa.launchpad.net/beineri/opt-qt591-xenial/ubuntu xenial main" >> /etc/apt/sources.list.d/qt.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C65D51784EDC19A871DBDBB710C56D0DE9977759

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  libyaml-libyaml-perl \
  qt59-meta-minimal
USER user

# kde anongit url alias
RUN git config --global url."git://anongit.kde.org/".insteadOf kde: && \
    git config --global url."ssh://git@git.kde.org/".pushInsteadOf kde: && \
    git clone kde:kdesrc-build

RUN mkdir /home/user/usr
RUN mkdir /home/user/usr/bin
RUN ln -s /home/user/kdesrc-build/kdesrc-build /home/user/usr/bin/
WORKDIR /home/user/kdesrc-build/
# TODO: share this with var.env somehow
ENV KF5=/home/user/usr
ENV QTDIR=/opt/qt59
ENV CMAKE_PREFIX_PATH=$KF5:$CMAKE_PREFIX_PATH
ENV XDG_DATA_DIRS=$KF5/share:$XDG_DATA_DIRS:/usr/share
ENV XDG_CONFIG_DIRS=$KF5/etc/xdg:$XDG_CONFIG_DIRS:/etc/xdg
ENV PATH=$KF5/bin:$QTDIR/bin:$PATH
ENV QT_PLUGIN_PATH=$KF5/lib/plugins:$KF5/lib64/plugins:$KF5/lib/x86_64-linux-gnu/plugins:$QTDIR/plugins:$QT_PLUGIN_PATH
ENV QML2_IMPORT_PATH=$KF5/lib/qml:$KF5/lib64/qml:$KF5/lib/x86_64-linux-gnu/qml:$QTDIR/qml
ENV QML_IMPORT_PATH=$QML2_IMPORT_PATH
ENV KDE_FULL_SESSION=true
ENV KDE_SESSION_VERSION=5
ENV SASL_PATH=/usr/lib/sasl2:$KF5/lib/sasl2

# Pull the source
RUN ./kdesrc-build --metadata-only frameworks
RUN ./kdesrc-build --src-only frameworks
USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  libudev-dev \
  libphonon4qt5-dev \
  libphonon4qt5experimental-dev \
  libqrencode-dev \
  libwayland-dev \
  libnm-dev \
  libqt5webkit5-dev \
  qt59quickcontrols2 \
  qt59script \
  qt59svg \
  qt59tools \
  qt59x11extras
USER user
RUN ./kdesrc-build --build-only frameworks

