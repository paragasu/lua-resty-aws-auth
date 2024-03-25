from openresty/openresty:1.11.2.1-centos
RUN yum install -y libtermcap-devel ncurses-devel libevent-devel readline-devel
RUN yum install -y lua.x86_64 lua-devel.x86_64 
Run yum install -y git
RUN curl -R -O http://luarocks.github.io/luarocks/releases/luarocks-3.9.2.tar.gz
RUN tar -zxf luarocks-3.9.2.tar.gz && cd luarocks-3.9.2 && \
    ./configure --with-lua-include=/usr/include \
    && make && make install
RUN luarocks install lua-resty-aws-auth
COPY ./nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
