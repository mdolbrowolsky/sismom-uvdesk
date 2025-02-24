# Usar imagem base do Ubuntu 24.04
FROM ubuntu:24.10

LABEL maintainer="marcia.schubert@inpe.br"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

# Instalar dependências, configurar timezone e atualizar o sistema
RUN echo 'path-exclude /usr/share/doc/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/locale/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    apt-get update && \
    apt-get install -y tzdata software-properties-common curl wget unzip \
    lsb-release apt-transport-https build-essential zlib1g-dev lsb-release \
    libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    echo "tzdata tzdata/Areas select America" | debconf-set-selections && \
    echo "tzdata tzdata/Zones/America select Sao_Paulo" | debconf-set-selections && \
    apt-get update && apt-get -y upgrade && apt-get clean

# Instalar Apache, PHP 8.3 e extensões necessárias, incluindo dom e imap
#RUN add-apt-repository ppa:ondrej/php && 
RUN apt-get update && \
    echo 'path-exclude /usr/share/doc/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/locale/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    apt-get -y install apache2 php8.3 php8.3-curl php8.3-intl php8.3-gd php8.3-xml \
    php8.3-mbstring php8.3-zip php8.3-mysqli php8.3-soap php8.3-fpm libapache2-mod-php8.3 \
    php8.3-gmp php8.3-bcmath php8.3-imagick php8.3-imap php8.3-cli php8.3-common \
    php8.3-opcache php8.3-readline php8.3-dom php8.3-iconv php8.3-ctype php8.3-bz2 \
    php8.3-calendar php8.3-pdo php8.3-xsl php8.3-mailparse php8.3-fileinfo \
    php-json php8.3-phpdbg php8.3-cgi libphp8.3-embed php8.3-posix php8.3-tokenizer \
    php8.3-xmlreader php8.3-phar php8.3-gmp php8.3-apcu php8.3-redis php8.3-xdebug \
    php8.3-ctype php8.3-exif php8.3-xmlwriter && \ 
    a2enmod proxy_fcgi setenvif && a2enconf php8.3-fpm && a2enmod rewrite && \
    apt-get clean

# Instalar MySQL e configurar senha de root e usuário
RUN echo 'path-exclude /usr/share/doc/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/locale/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install mysql-server mysql-client && \
    sed -i 's|/nonexistent|/var/lib/mysql|' /etc/passwd && \
    usermod -d /var/lib/mysql mysql && \
    /etc/init.d/mysql stop
COPY mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

# Instalar UVDesk
WORKDIR /var/www
RUN wget https://cdn.uvdesk.com/uvdesk/downloads/opensource/uvdesk-community-current-stable.zip && \
    unzip uvdesk-community-current-stable.zip && \
    mv uvdesk-community-v1.1.7 uvdesk && \
    rm -f uvdesk-*.zip && \
    php -r "copy('https://getcomposer.org/composer-stable.phar', 'composer.phar');" && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    cd /var/www/uvdesk && \
    chown -R www-data:www-data /var/www/uvdesk && \
    chmod -R 775 * && \
    composer update

COPY .env /var/www/uvdesk/.env

# Permitir a troca de senha no UVDesk
COPY updateSupportAgent.html.twig \
     uvdesk/vendor/uvdesk/core-framework/Resources/views/Agents/updateSupportAgent.html.twig
COPY updateSupportCustomer.html.twig \
     uvdesk/vendor/uvdesk/core-framework/Resources/views/Customers/updateSupportCustomer.html.twig

# Alterar a rota no uvdesk
COPY uvdesk.yaml /var/www/uvdesk/config/packages/uvdesk.yaml
RUN chown -R www-data:www-data /var/www/uvdesk 

#Alterar o logotipo do dashboard
RUN cd /var/www/uvdesk && \
    mkdir -p /var/www/uvdesk/public/images 
COPY Sismom_novo.svg /var/www/uvdesk/public/images/Sismom_novo.svg
COPY Sismom_novo.svg /var/www/uvdesk/vendor/uvdesk/core-framework/Resources/public/images
COPY sismom-logo.svg /var/www/uvdesk/vendor/uvdesk/core-framework/Resources/public/images
COPY  uv-avatar-sismom.png /var/www/uvdesk/vendor/uvdesk/core-framework/Resources/public/images
COPY sidebar.html.twig /var/www/uvdesk/vendor/uvdesk/core-framework/Resources/views/Templates/sidebar.html.twig

#Alterar página do login
COPY login.html.twig /var/www/uvdesk/vendor/uvdesk/core-framework/Resources/views/login.html.twig

#Alterar página de troca de password
COPY forgotPassword.html.twig /var/www/uvdesk/vendor/uvdesk/core-framework/Resources/views/forgotPassword.html.twig

#Resolver problema de opendir(/var/lib/php/sessions) failed: Permission denied
COPY framework.yaml /var/www/uvdesk/config/packages/

#Alterar página de reset de password
COPY resetPassword.html.twig /var/www/uvdesk/vendor/uvdesk/core-framework/Resources/views/resetPassword.html.twig
RUN chown -R www-data:www-data /var/www/uvdesk && \
    chmod -R 775 /var/www/uvdesk

#Instalar/Publicar os Assets do Bundle
RUN cd /var/www/uvdesk && \
    php bin/console assets:install public --symlink

# Limpar cache do uvdesk
RUN cd /var/www/uvdesk && \
    php bin/console cache:clear && \
    php bin/console cache:warmup

# Configurar o Apache para UVDesk
RUN echo 'Alias /uvdesk "/var/www/uvdesk/public"\n<Directory /var/www/uvdesk/public>\nRequire all granted\nOptions Indexes FollowSymLinks\nAllowOverride All\nOrder allow,deny\nAllow from all\n</Directory>' > /etc/apache2/sites-available/uvdesk.conf && \
    a2ensite uvdesk.conf && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    phpenmod imap && \
    service apache2 restart

# Atualização do OPENSSL
RUN apt-get update && \
    apt-get remove -y --purge openssl libssl-dev && \ 
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends git perl ca-certificates && \
    update-ca-certificates &&\
    cd /usr/local/src && \
    git clone https://github.com/openssl/openssl.git && \
    cd openssl && \
    git checkout openssl-3.2.0 || (echo "Erro no checkout" && exit 1) && \
    git log -1 || (echo "Erro no log" && exit 1) && \
    ./config || (echo "Erro no config" && exit 1) && \
    make || (echo "Erro no make" && exit 1) && \
    make install || (echo "Erro no make install" && exit 1) && \
    ldconfig || (echo "Erro no ldconfig" && exit 1) && \
    echo "export PATH=/usr/local/bin:\$PATH" >> /root/.bashrc && \
    echo "export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:\$LD_LIBRARY_PATH" >> /root/.bashrc && \
    cd /usr/local/src/openssl && \
    cp libssl.so.3 libcrypto.so.3 /usr/local/lib && \
    cd /usr/local/lib && \
    ln -sf libcrypto.so.3 libcrypto.so && \
    ln -sf libssl.so.3 libssl.so && \
    ln -sf libcrypto.so.3 libcrypto.so && \
    rm -rf /usr/local/src/*

# Copia do certificado e configuração do certificado do google
COPY php.ini /etc/php/8.3/cli/php.ini
RUN cd /tmp && \
    openssl s_client -connect imap.gmail.com:993 -showcerts </dev/null 2>/dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}' && \
    cat cert1.pem cert2.pem cert3.pem > gmail-complete.crt && \
    cp gmail-complete.crt  /etc/ssl/certs/gmail-complete.crt
RUN update-ca-certificates && \
    /etc/init.d/apache2 stop ; /etc/init.d/php8.3-fpm stop && \
    /etc/init.d/apache2 start ; /etc/init.d/php8.3-fpm start && \

#Limpeza do sistema
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc /usr/share/man

# Expor porta 80 para o Apache
EXPOSE 80

# Definir volumes do UVDesk e MySQL
VOLUME ["/var/www/", "/var/lib/mysql"]

# Copiar o script de inicialização e definir como comando de entrada
COPY start-services.sh /usr/local/bin/start-services.sh
COPY mysql_start.sh /usr/local/bin/mysql_start.sh
RUN chmod +x /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/mysql_start.sh
CMD ["/bin/bash", "-c", "/usr/local/bin/start-services.sh"]

WORKDIR /var/www/uvdesk
