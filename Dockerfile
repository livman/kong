FROM kong:2.4-centos
USER root

RUN yum install telnet -y

RUN luarocks install lua-resty-jwt

RUN mkdir /plugins

COPY ./plugins/custom-auth /usr/local/share/lua/5.1/
COPY ./plugins/custom-header /usr/local/share/lua/5.1/

#WORKDIR /custom-plugins/custom-auth

#RUN luarocks make

#COPY ./plugins/ /usr/local/share/lua/5.1/kong/plugins

COPY deployment/resources/my-server.kong.conf /etc/kong/my-server.kong.conf

CMD kong start --conf /etc/kong/my-server.kong.conf

USER kong

