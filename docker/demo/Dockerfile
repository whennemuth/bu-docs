FROM ubuntu:12.04

# Install dependencies
RUN apt-get update -y
RUN apt-get install -y apache2

# Install apache and write hellow world message
# RUN echo "Hello World!" > /var/www/index.html
VOLUME /var/www/

# Configure apache
RUN a2enmod rewrite
RUN chown -R www-data:www-data /var/www
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

ENV MY_STATIC_ENV apples

ARG MY_BUILD_ARG
ENV MY_BUILD_ENV $MY_BUILD_ARG

EXPOSE 80

# CMD ["/usr/sbin/apache2", "-D",  "FOREGROUND"]

COPY start-apache.sh /start-apache.sh
RUN chmod -v +x /start-apache.sh
CMD ["/start-apache.sh"]
