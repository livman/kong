FROM registry.devopsnonprd.vayuktbcs:8082/kong:3.1.1-alpine

USER root

#ENV http_proxy=100.127.69.200:8085
#ENV https_proxy=100.127.69.200:8085


RUN apk --no-cache add curl busybox-extras git vim

RUN luarocks install lua-resty-jwt

RUN luarocks install kong-circuit-breaker


COPY deployment/resources/deck_1.12.2_linux_amd64.tar.gz deck.tar.gz
RUN tar -xf deck.tar.gz -C /tmp
RUN cp /tmp/deck /usr/local/bin/

RUN apk add --no-cache tzdata
ENV TZ=Asia/Bangkok

COPY ./plugins/custom-auth /usr/local/share/lua/5.1/
COPY ./plugins/custom-header /usr/local/share/lua/5.1/


COPY deployment/resources/my-server.kong.conf /etc/kong/my-server.kong.conf

CMD kong start --conf /etc/kong/my-server.kong.conf

ENV http_proxy=""
ENV https_proxy=""

RUN chown -R 100:100 /usr/local/share/lua/5.1/

USER kong