FROM tomcat:8.5

RUN apt-get update && apt-get -y upgrade

WORKDIR /usr/local/tomcat

COPY target/*.war   /usr/local/tomcat/webapps/app.war


EXPOSE 8080

