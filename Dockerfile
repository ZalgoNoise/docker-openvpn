# Original credit: https://github.com/jpetazzo/dockvpn
# Docker-OpenVPN credit: https://github.com/kylemanna/docker-openvpn

# Smallest base image
FROM alpine:latest
LABEL maintainer="Zalgo Noise <zalgo.noise@gmail.com>"

VOLUME ["/etc/openvpn"]
# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp
# Allow entrypoint script to autoconfigure a new server (for easy subnetting)
ENTRYPOINT ["/entrypoint.sh"]
CMD ["ovpn_run"]
# Needed by scripts - combined to a single layer
# $EASYRSA_CRL_DAYS : Prevents refused client connection because of an expired CRL
ENV OPENVPN="/etc/openvpn" EASYRSA="/usr/share/easy-rsa" EASYRSA_PKI="$OPENVPN/pki" EASYRSA_VARS_FILE="$OPENVPN/vars" EASYRSA_CRL_DAYS="3650"

# One single layer for adding files
ADD ./rootfs /


RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories  \
    && apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester \
    && ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/* \
    && chmod a+x /usr/local/bin/*
