FROM sameersbn/ubuntu:16.04.20180124

MAINTAINER pramod@damantra.io

RUN apt-get update && \ 
  apt-get install -y software-properties-common

RUN apt-get install sudo


RUN adduser --disabled-password --gecos '' hduser
RUN adduser hduser sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# We will be running our Spark jobs as `hduser` user.
USER root

# Scala related variables.
ARG SCALA_VERSION=2.11.8
ARG SCALA_BINARY_ARCHIVE_NAME=scala-${SCALA_VERSION}
ARG SCALA_BINARY_DOWNLOAD_URL=http://downloads.lightbend.com/scala/${SCALA_VERSION}/${SCALA_BINARY_ARCHIVE_NAME}.tgz

# MAVEN related variables.
ARG MAVEN_VERSION=3.3.9
ARG MAVEN_BINARY_ARCHIVE_NAME=apache-maven-${MAVEN_VERSION}
ARG MAVEN_BINARY_DOWNLOAD_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_BINARY_ARCHIVE_NAME}-bin.tar.gz

# Spark related variables.
ARG SPARK_VERSION=2.2.1
ARG SPARK_BINARY_ARCHIVE_NAME=spark-${SPARK_VERSION}-bin-hadoop2.6
ARG SPARK_BINARY_DOWNLOAD_URL=https://archive.apache.org/dist/spark/spark-2.2.1/${SPARK_BINARY_ARCHIVE_NAME}.tgz

# Kafka related variables.
ARG CONFLUENT_KAFKA_VERSION=3.2.0
ARG CONFLUENT_KAFKA_BINARY_ARCHIVE_NAME=confluent-${CONFLUENT_KAFKA_VERSION}
ARG CONFLUENT_KAFKA_BINARY_DOWNLOAD_URL=http://packages.confluent.io/archive/3.2/confluent-oss-${CONFLUENT_KAFKA_VERSION}-2.11.tar.gz

# Cassandra related variables
ARG CASSANDRA_VERSOIN=3.11.1
ARG CASSANDRA_BINARY_ARCHIVE_NAME=apache-cassandra-${CASSANDRA_VERSOIN}
ARG CASSANDRA_BINARY_DOWNLOAD_URL=https://www.apache.org/dist/cassandra/${CASSANDRA_VERSOIN}/${CASSANDRA_BINARY_ARCHIVE_NAME}-bin.tar.gz

# Install Java.
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/cache/oracle-jdk8-installer

USER hduser

# Working directory is set to the home folder of `hduser` user.
WORKDIR /home/hduser
  
# Install vim
RUN sudo apt-get install -yqq vim screen tmux

#Install git
RUN sudo apt-get install -yqq git-core

# Install python dev toots for easy_install	
RUN	sudo apt-get install -yqq python-setuptools python-dev build-essential
	
# Install pip	
RUN sudo easy_install pip

# Install python mysql
RUN sudo apt-get -yqq install python-dev libmysqlclient-dev && \
    sudo pip install MySQL-python

# Install airflow
RUN sudo pip install apache-airflow && \
    airflow initdb

	
RUN sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo rm -rf /tmp/*  
  
RUN cd /usr/local/ && \
    sudo wget -qO - ${SCALA_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/ && \
	sudo chown -R hduser:hduser ${SCALA_BINARY_ARCHIVE_NAME} && \
	sudo ln -s ${SCALA_BINARY_ARCHIVE_NAME} scala && \
	sudo chown  hduser:hduser scala


RUN cd /usr/local/ && \
    sudo wget -qO - ${MAVEN_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/  && \
    sudo chown -R hduser:hduser ${MAVEN_BINARY_ARCHIVE_NAME} && \
	sudo ln -s ${MAVEN_BINARY_ARCHIVE_NAME} maven && \
    sudo chown  hduser:hduser maven

RUN cd /usr/local/ && \
    sudo wget -qO - ${SPARK_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/  && \
    sudo chown -R hduser:hduser ${SPARK_BINARY_ARCHIVE_NAME} && \
	sudo ln -s ${SPARK_BINARY_ARCHIVE_NAME} spark && \
    sudo chown  hduser:hduser spark && \
	cp spark/conf/log4j.properties.template spark/conf/log4j.properties
	
RUN cd /usr/local/ && \
    sudo wget -qO - ${CONFLUENT_KAFKA_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/  && \
    sudo chown -R hduser:hduser ${CONFLUENT_KAFKA_BINARY_ARCHIVE_NAME} && \
	sudo ln -s ${CONFLUENT_KAFKA_BINARY_ARCHIVE_NAME} kafka && \
    sudo chown  hduser:hduser kafka

RUN cd /usr/local/ && \
    sudo wget -qO - ${CASSANDRA_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/  && \
    sudo chown -R hduser:hduser ${CASSANDRA_BINARY_ARCHIVE_NAME} && \
	sudo ln -s ${CASSANDRA_BINARY_ARCHIVE_NAME} cassandra && \
    sudo chown  hduser:hduser cassandra

# Configure env variables for Java, Scala, Maven,Spark, Kafka, Cassandra.
# Also configure PATH env variable to include binary folders of Java, Scala, Spark, Kafka and Cassandra.	
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV SCALA_HOME  /usr/local/scala
ENV MAVEN_HOME  /usr/local/maven
ENV SPARK_HOME  /usr/local/spark
ENV KAFKA_HOME /usr/local/kafka
ENV CASSANDRA_HOME /usr/local/cassandra

ENV PATH   $JAVA_HOME/bin:$SCALA_HOME/bin:$MAVEN_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$KAFKA_HOME/bin:$CASSANDRA_HOME/bin:$PATH
	
USER root
#WORKDIR /home/hduser

ENV MYSQL_USER=mysql \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server \
 && rm -rf ${MYSQL_DATA_DIR} \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 4040 8080 8081 7077 6066 2181 9092 9042  8070 8090 5555 8793 3306

VOLUME ["${MYSQL_DATA_DIR}", "${MYSQL_RUN_DIR}"]
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/usr/bin/mysqld_safe"]
