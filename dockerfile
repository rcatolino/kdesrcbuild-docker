FROM debian:stretch
MAINTAINER Raphael Catolino "raphael.catolino@gmail.com"

ENV SHELL /bin/bash

RUN echo "deb-src http://deb.debian.org/debian stretch main" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian stretch-updates main" >> /etc/apt/sources.list

RUN cat /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get build-dep -y -q qtbase5-dev
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
  libclang-dev \
  libegl1-mesa-dev \
  libepoxy-dev \
  libgcrypt20-dev \
  libgif-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgtk-3-dev \
  libjson-perl \
  "libkf5*-dev" \
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
  libxml2-dev \
  libxml-parser-perl \
  libxslt-dev \
  llvm \
  modemmanager-dev \
  network-manager-dev \
  oxygen-icon-theme \
  shared-mime-info \
  xserver-xorg-input-synaptics-dev \
  xsltproc

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get build-dep -y -q xserver-xorg-dev

# Generate utf8 locale
RUN apt-get update -q && DEBIAN_FRONTEND=noninteractive apt-get install -y -q locales
RUN touch /etc/locale-gen
RUN sed -i "s/#.*\(en_US.UTF-8 UTF-8\)/\1/" /etc/locale.gen
RUN /usr/sbin/locale-gen

# Install various utilities for remote access.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  qdbus-qt5 \
  curl \
  net-tools \
  vim \
  openssh-server \
  supervisor \
  tmux \
  xvfb \
  x11vnc \
  x11-xserver-utils

RUN mkdir /var/run/sshd
RUN touch /etc/supervisord.log

# Configure Supervisor.
ADD https://raw.githubusercontent.com/rcatolino/kdesrcbuild-docker/master/supervisord.conf /etc/supervisord.conf
RUN chown root:root /etc/supervisord.conf

# Disallow password logins in openssh
RUN sed -i "s/^[#\s]*PasswordAuthentication[\s]*[yYnN].*$/PasswordAuthentication no/;s/^[#\s]*ChallengeResponseAuthentication[\s]*[yYnN].*$/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config

RUN useradd -U -m user
RUN echo 'user:' | chpasswd -e
WORKDIR /home/user/

ADD https://raw.githubusercontent.com/rcatolino/kdesrcbuild-docker/master/var.env ./var.env
RUN chown user:user var.env
RUN echo 'source /home/user/var.env' >> .bashrc
#ADD https://raw.githubusercontent.com/rcatolino/kdesrcbuild-docker/master/kdesrc-buildrc ./.kdesrc-buildrc
ADD kdesrc-buildrc ./.kdesrc-buildrc
RUN chown user:user .kdesrc-buildrc

USER user
ENV HOME /home/user

# Install Cloud9 and noVNC (without administrator privileges).
RUN curl -L https://raw.githubusercontent.com/c9/install/master/install.sh | bash
RUN git clone https://github.com/kanaka/noVNC /home/user/novnc/

# kde anongit url alias
RUN git config --global url."git://anongit.kde.org/".insteadOf kde: && \
    git config --global url."ssh://git@git.kde.org/".pushInsteadOf kde: && \
    git clone kde:kdesrc-build

WORKDIR /home/user/kdesrc-build/
RUN mkdir /home/user/work
ENV KF5=/home/user/work/install
ENV QTDIR=/usr
ENV XDG_DATA_DIRS=$KF5/share:$XDG_DATA_DIRS:/usr/share
ENV XDG_CONFIG_DIRS=$KF5/etc/xdg:$XDG_CONFIG_DIRS:/etc/xdg
ENV PATH=$KF5/bin:$QTDIR/bin:$PATH
ENV QT_PLUGIN_PATH=$KF5/lib/plugins:$KF5/lib64/plugins:$KF5/lib/x86_64-linux-gnu/plugins:$QTDIR/plugins:$QT_PLUGIN_PATH
ENV QML2_IMPORT_PATH=$KF5/lib/qml:$KF5/lib64/qml:$KF5/lib/x86_64-linux-gnu/qml:$QTDIR/qml
ENV QML_IMPORT_PATH=$QML2_IMPORT_PATH
ENV KDE_SESSION_VERSION=5
ENV KDE_FULL_SESSION=true

# Pull the source
RUN ./kdesrc-build --metadata-only
RUN ./kdesrc-build --src-only

WORKDIR /home/user/
USER root
# Expose the remote access ports and run the server.
EXPOSE 22 8088
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]

