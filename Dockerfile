FROM healthcatalyst/fabric.baseos:latest

LABEL maintainer="Health Catalyst"
LABEL version="1.0"

# Install required packages
RUN yum install -y wget krb5-libs krb5-workstation ntp rsync dos2unix; yum clean all

# Install Java
# RUN yum -y install java-1.8.0-openjdk; yum clean all

RUN wget -O jdk.rpm --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
http://javadl.oracle.com/webapps/download/AutoDL?BundleId=227541_e758a0de34e24606bca991d704f6dcbf \
&& yum install -y ./jdk.rpm \
&& yum clean all \
&& rm -f jdk.rpm

# Install Mirth-Connect
RUN wget -O mirthconnect.rpm http://downloads.mirthcorp.com/connect/3.5.1.b194/mirthconnect-3.5.1.b194-linux.rpm \
&& yum install -y mirthconnect.rpm \
&& yum clean all \
&& rm -f mirthconnect.rpm

# Install Microsoft JDBC Driver
RUN wget -O - https://download.microsoft.com/download/0/2/A/02AAE597-3865-456C-AE7F-613F99F850A8/enu/sqljdbc_6.0.8112.100_enu.tar.gz \
| tar xz \
&& cp sqljdbc_6.0/enu/jre8/sqljdbc42.jar /opt/mirthconnect/custom-lib \
&& rm -rf sqljdbc_6.0 \
; sed -i '/<\/drivers>/ i\ \t<driver class="com.microsoft.sqlserver.jdbc.SQLServerDriver" name="MS SQL Server" template="jdbc:sqlserver://host:port;databaseName=dbname" selectLimit="SELECT TOP 1 * FROM ?" />' /opt/mirthconnect/conf/dbdrivers.xml

# Install RabbitMQ Java Client
RUN wget -O ampq-client.jar  http://central.maven.org/maven2/com/rabbitmq/amqp-client/4.0.2/amqp-client-4.0.2.jar \
&& mv ampq-client.jar /opt/mirthconnect/custom-lib \
&& wget -O slf4j-api.jar http://central.maven.org/maven2/org/slf4j/slf4j-api/1.7.21/slf4j-api-1.7.21.jar \
&& mv slf4j-api.jar /opt/mirthconnect/custom-lib \
&& wget -O slf4j-simple.jar http://central.maven.org/maven2/org/slf4j/slf4j-simple/1.7.22/slf4j-simple-1.7.22.jar \
&& mv slf4j-simple.jar /opt/mirthconnect/custom-lib

ADD conf/mirthconnect/* /opt/mirthconnect/

ADD conf/appdata/* /opt/mirthconnect/appdata/

ADD conf/channels/* /opt/mirthconnect_channels/

ADD conf/database/* /opt/mirthconnect_database/

ADD conf/mysql/* /opt/mirthconnect_mysql/

ADD docker-entrypoint.sh ./docker-entrypoint.sh

RUN dos2unix /opt/mirthconnect/startmirthandrenewcredentials.sh \
    && chmod +x /opt/mirthconnect/startmirthandrenewcredentials.sh \
    && dos2unix /opt/mirthconnect_channels/deployrealtimechannel.sh \
    && chmod +x /opt/mirthconnect_channels/deployrealtimechannel.sh \
	&& dos2unix /opt/mirthconnect_database/switchtosqlserver.sh \
	&& chmod +x /opt/mirthconnect_database/switchtosqlserver.sh \
	&& dos2unix /opt/mirthconnect_mysql/* \
	&& chmod +x /opt/mirthconnect_mysql/* \
	&& dos2unix ./docker-entrypoint.sh \
	&& chmod +x ./docker-entrypoint.sh 

EXPOSE 8080 8443 6661

# Start Mirth-Connect as a service
ENTRYPOINT [ "./docker-entrypoint.sh" ]
