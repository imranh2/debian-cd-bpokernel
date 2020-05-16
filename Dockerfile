FROM debian:stable

RUN echo "deb http://deb.debian.org/debian stable-backports main contrib non-free" >> /etc/apt/sources.list.d/backports.list
RUN echo "deb-src http://deb.debian.org/debian stable main contrib non-free" >> /etc/apt/sources.list.d/src.list
RUN echo "deb-src http://deb.debian.org/debian-security/ stable/updates main contrib non-free" >> /etc/apt/sources.list.d/src.list
RUN echo "deb-src http://deb.debian.org/debian stable-updates main contrib non-free" >> /etc/apt/sources.list.d/src.list
RUN apt update
RUN apt install sudo -y

COPY ./build-kernelbpo-di-cd.sh .

ENTRYPOINT ["/build-kernelbpo-di-cd.sh"]
