#!/bin/bash

# Iniciar Apache
service apache2 stop
service apache2 start &

# Iniciar php
service php8.3-fpm start &

# Iniciar MySQL
/usr/local/bin/mysql_start.sh &

# Manter o container ativo (opção alternativa para um servidor web)
tail -f /dev/null
