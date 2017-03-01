
FROM debian:jessie

MAINTAINER Guillermo Garcia <ggarcia@realidadfutura.com>

RUN  echo "Europe/Madrid" > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata

WORKDIR /root

RUN echo 'deb-src http://deb.debian.org/debian jessie main' >> /etc/apt/sources.list

RUN export DEBIAN_FRONTEND=noninteractive TERM=linux \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      dpkg-dev \
      iptables \
      libssl-dev \
      patch \
      squid-langpack \
      ssl-cert \
  && apt-get source -y squid3 squid-langpack \
  && apt-get build-dep -y squid3 squid-langpack

COPY squid3.patch mime.conf /root/

RUN cd squid3-3.?.? \
    && patch -p1 < /root/squid3.patch \
    && export NUM_PROCS=`grep -c ^processor /proc/cpuinfo` \
    && (dpkg-buildpackage -b -j${NUM_PROCS} \
        || dpkg-buildpackage -b -j${NUM_PROCS})

RUN DEBIAN_FRONTEND=noninteractive TERM=linux dpkg -i \
     /root/squid3-common_3*.deb \
     /root/squid3_3*.deb \
  || apt-get -yf install

RUN mkdir -p /etc/squid3/ssl_cert \
  && cat /root/mime.conf >> /usr/share/squid3/mime.conf

RUN  apt-get -qy --no-install-recommends install sarg nginx cron supervisor \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY start.sh /root/start.sh
COPY squid.conf /etc/squid3/squid.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY sarg.conf /etc/sarg/sarg.conf

VOLUME /var/spool/squid3 /etc/squid3/ssl_cert /var/log/squid3 /var/www/html
EXPOSE 3128 3129 3130 80

CMD ["/usr/bin/supervisord"]
