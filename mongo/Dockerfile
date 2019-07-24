FROM centos:7

COPY mongodb-org-3.6.repo /etc/yum.repos.d/

RUN \
  yum update -y && \
  yum install -y mongodb-org && \
  mkdir -p /var/mongo/dump && \
  mkdir -p /var/mongo/script

USER root

WORKDIR /var/mongo/script

CMD ["sh", "/var/mongo/script/fillname.sh"]

