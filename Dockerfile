# Use a imagem do PHP com Apache FPM
FROM php:8.1-fpm

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev \
    apache2-utils \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql

# Instalar Apache
RUN apt-get install -y apache2

# Habilitar mod_rewrite
RUN a2enmod rewrite

# Configurar o Apache para usar o PHP-FPM
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configurar o Apache para usar o PHP-FPM
RUN echo '<IfModule mod_proxy_fcgi.c>' > /etc/apache2/sites-available/000-default.conf \
    && echo '    <FilesMatch \\.php$>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        SetHandler proxy:fcgi://127.0.0.1:9000' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    </FilesMatch>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '</IfModule>' >> /etc/apache2/sites-available/000-default.conf

# Limpar cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar extensões do PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crie as pastas necessárias do Laravel (caso não existam)
RUN mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache

# Configurar permissões para o Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copiar os arquivos do aplicativo Laravel
COPY . /var/www/html

# Copiar permissões dos arquivos do aplicativo
COPY --chown=www-data:www-data . /var/www/html

# Definir o usuário como www-data
USER www-data

# Expor a porta 80 para o Apache
EXPOSE 80

# Comando para rodar o Apache e o PHP-FPM
CMD ["apache2-foreground"]
