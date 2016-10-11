# Copy this file to the EC2 web instance and run it.

cd /tmp
if [ -d apache-shib ] ; then rm -f -r apache-shib; fi
if [ -f apache-shib.tar ] ; then rm -f apache-shib.tar; fi
mkdir apache-shib
cd apache-shib
cp /etc/pki/tls/private/kuali*.key .
cp /etc/pki/tls/certs/kuali*.cer .
cp /etc/shibboleth/idp-metadata.xml .
cp /etc/shibboleth/sp-cert.pem .
cp /etc/shibboleth/sp-key.pem .
cd ..
echo "if [ ! -d /opt/kuali/tls/certs ] ; then mkdir -p /opt/kuali/tls/certs; fi" >> unpack.sh
echo "if [ ! -d /opt/kuali/tls/private ] ; then mkdir -p /opt/kuali/tls/private; fi " >> unpack.sh
echo "if [ ! -d /var/log/kuali/httpd ] ; then mkdir -p /var/log/kuali/httpd; fi " >> unpack.sh
echo "if [ ! -d /opt/kuali/main/config ] ; then mkdir -p /opt/kuali/main/config; fi " >> unpack.sh
echo "if [ ! -d /var/log/kuali/printing ] ; then mkdir -p /var/log/kuali/printing; fi " >> unpack.sh
echo "if [ ! -d /var/log/kuali/tomcat ] ; then mkdir -p /var/log/kuali/tomcat; fi " >> unpack.sh
echo "if [ ! -d /var/log/kuali/javamelody ] ; then mkdir -p /var/log/kuali/javamelody; fi " >> unpack.sh
echo "tar -xf apache-shib.tar -C /opt/kuali/tls/private/ --wildcards --no-anchored '*.key' --strip-components=1" >> unpack.sh
echo "tar -xf apache-shib.tar -C /opt/kuali/tls/certs/ --wildcards --no-anchored '*.cer' --strip-components=1" >> unpack.sh
echo "tar -xf apache-shib.tar -C /opt/kuali/tls/certs/ 'apache-shib/idp-metadata.xml' --strip-components=1" >> unpack.sh
echo "tar -xf apache-shib.tar -C /opt/kuali/tls/certs/ 'apache-shib/sp-cert.pem' --strip-components=1" >> unpack.sh
echo "tar -xf apache-shib.tar -C /opt/kuali/tls/certs/ 'apache-shib/sp-key.pem' --strip-components=1" >> unpack.sh
tar -cvf apache-shib.tar apache-shib
tar --append --file=apache-shib.tar unpack.sh
if [ -d apache-shib ] ; then rm -f -r apache-shib; fi
rm -f unpack.sh
