FROM janitortechnology/ubuntu-dev
MAINTAINER Raphael Catolino "raphael.catolino@gmail.com"

ENV SHELL /bin/bash
WORKDIR /home/user

USER root
RUN echo "deb http://archive.neon.kde.org/dev/stable xenial main" \
  > /etc/apt/sources.list.d/neon.list
RUN echo "deb-src http://archive.neon.kde.org/dev/stable xenial main" \
  >> /etc/apt/sources.list.d/neon.list
ADD https://archive.neon.kde.org/public.key /tmp/public.key
RUN apt-key add /tmp/public.key

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  bison \
  bzr \
  cmake \
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
  libegl1-mesa-dev \
  libepoxy-dev \
  libgcrypt20-dev \
  libgif-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgtk-3-dev \
  libjson-perl \
  liblmdb-dev \
  libnm-dev \
  libnm-glib-dev \
  libnm-util-dev \
  libpolkit-agent-1-dev \
  libpwquality-dev \
  libqrencode-dev \
  libqt5x11extras5-dev \
  libqt5svg5-dev \
  libqt5webkit5-dev \
  libqt5xmlpatterns5-dev \
  libudev-dev \
  libvlccore-dev \
  libvlc-dev \
  libwww-perl \
  libxapian-dev \
  libxcb-keysyms1-dev \
  libxcb-xkb-dev \
  libxml2-dev \
  libxml-parser-perl \
  libxrender-dev \
  libxslt-dev \
  libyaml-libyaml-perl \
  llvm \
  llvm-3.6 \
  modemmanager-dev \
  network-manager-dev \
  oxygen-icon-theme \
  pkg-config \
  qtbase5-private-dev \
  qtdeclarative5-dev \
  qtquickcontrols2-5-dev \
  qtscript5-dev \
  qttools5-dev \
  shared-mime-info \
  xserver-xorg-input-synaptics-dev \
  xsltproc

# Typical KDE development tools if you want to work *in* the container.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  cppcheck \
  kate \
  konsole
# Install KDE frameworks-development, so you can work on applications immediately
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
	libkf5activities-dev \
	libkf5activitiesstats-dev \
	libkf5archive-dev \
	libkf5attica-dev \
	libkf5auth-bin-dev \
	libkf5auth-dev \
	libkf5baloowidgets-dev \
	libkf5bookmarks-dev \
	libkf5cddb-dev \
	libkf5codecs-dev \
	libkf5compactdisc-dev \
	libkf5completion-dev \
	libkf5config-dev \
	libkf5configwidgets-dev \
	libkf5coreaddons-dev \
	libkf5crash-dev \
	libkf5dbusaddons-dev \
	libkf5declarative-dev \
	libkf5dnssd-dev \
	libkf5doctools-dev \
	libkf5emoticons-dev \
	libkf5filemetadata-dev \
	libkf5globalaccel-dev \
	libkf5grantleetheme-dev \
	libkf5gravatar-dev \
	libkf5guiaddons-dev \
	libkf5i18n-dev \
	libkf5iconthemes-dev \
	libkf5idletime-dev \
	libkf5itemmodels-dev \
	libkf5itemviews-dev \
	libkf5jobwidgets-dev \
	libkf5jsembed-dev \
	libkf5kcmutils-dev \
	libkf5kio-dev \
	libkf5kjs-dev \
	libkf5networkmanagerqt-dev \
	libkf5newstuff-dev \
	libkf5notifications-dev \
	libkf5notifyconfig-dev \
	libkf5package-dev \
	libkf5parts-dev \
	libkf5plasma-dev \
	libkf5prison-dev \
	libkf5pty-dev \
	libkf5purpose-dev \
	libkf5runner-dev \
	libkf5screen-dev \
	libkf5service-dev \
	libkf5solid-dev \
	libkf5sonnet-dev \
	libkf5style-dev \
	libkf5su-dev \
	libkf5syntaxhighlighting-dev \
	libkf5sysguard-dev \
	libkf5texteditor-dev \
	libkf5textwidgets-dev \
	libkf5threadweaver-dev \
	libkf5unitconversion-dev \
	libkf5wallet-dev \
	libkf5wayland-dev \
	libkf5webkit-dev \
	libkf5widgetsaddons-dev \
	libkf5windowsystem-dev \
	libkf5xmlgui-dev \
	libkf5xmlrpcclient-dev \
	libphonon4qt5-dev

ADD var.env ./var.env
RUN chown user:user var.env
# Better in .pam_environment maybe ?
RUN echo 'source /home/user/var.env' >> .bashrc
ADD kdesrc-buildrc ./.kdesrc-buildrc
RUN chown user:user .kdesrc-buildrc

USER user

# kde anongit url alias
RUN git config --global url."git://anongit.kde.org/".insteadOf kde: && \
    git config --global url."ssh://git@git.kde.org/".pushInsteadOf kde: && \
    git clone kde:kdesrc-build

# Configure konsole to not be horribly ugly
RUN mkdir -p /home/user/.config /home/user/.local/share/konsole
ADD konsolerc ./.config/konsolerc
ADD konsole.Default.profile .local/share/konsole/Default.profile

RUN mkdir /home/user/usr
RUN mkdir /home/user/src
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
RUN ./kdesrc-build --metadata-only workspace
RUN ./kdesrc-build --src-only workspace
# "Selected" applications ready as well
RUN ./kdesrc-build --src-only konversation okular

# Don't actually build, though
# RUN ./kdesrc-build --include-dependencies frameworks || true

