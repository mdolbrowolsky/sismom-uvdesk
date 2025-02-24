#!/bin/bash

# Carrega as variáveis do arquivo .env
if [ -f /var/www/uvdesk/.env ]; then
    export $(grep -v '^#' /var/www/uvdesk/.env | xargs)
else
    echo "Arquivo .env não encontrado."
    exit 1
fi

# Inicia o MySQL diretamente sem o mysqld_safe
service mysql stop

mysqld_safe --user=mysql &

# Espera o MySQL estar disponível
until mysqladmin ping -h localhost --silent; do
    echo "Aguardando MySQL iniciar..."
    sleep 2
done

# Configura o método de autenticação e define a senha root
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_ROOT_PASSWORD}';" || echo "Usuário root já configurado."

# Verifica se a senha foi configurada corretamente
if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" &> /dev/null; then
    echo "Conectado com sucesso ao MySQL com a senha configurada para o root."

    # Cria o usuário e define permissões
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'localhost';"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
    echo "Configuração do MySQL concluída com sucesso."
else
    echo "Falha ao configurar a senha do root ou conexão não permitida."
fi
