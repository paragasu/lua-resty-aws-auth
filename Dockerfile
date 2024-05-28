from openresty/openresty:1.25.3.1-2-centos7
RUN yum install -y libtermcap-devel ncurses-devel libevent-devel readline-devel
RUN yum install -y lua lua-devel 
Run yum install -y git
RUN curl -R -O http://luarocks.github.io/luarocks/releases/luarocks-3.9.2.tar.gz
RUN tar -zxf luarocks-3.9.2.tar.gz && cd luarocks-3.9.2 && \
    ./configure --with-lua-include=/usr/include \
    && make && make install
RUN luarocks install lua-resty-aws-auth && luarocks install lua-resty-crypto
COPY ./nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
# COPY ./lib/resty/aws_auth.lua /usr/local/share/lua/5.1/resty/aws_auth.lua