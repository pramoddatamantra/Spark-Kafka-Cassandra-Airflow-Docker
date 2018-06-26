FROM openjdk:8

MAINTAINER Pramod Narayana <pramod@datamantra.io>

RUN apt-get -yqq update
RUN apt-get install sudo

RUN adduser --disabled-password --gecos '' hduser
RUN adduser hduser sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# We will be running our Spark jobs as `hduser` user.
USER hduser

# Working directory is set to the home folder of `hduser` user.
WORKDIR /home/hduser

CMD /bin/bash


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

# Install vim
RUN sudo apt-get install -yqq vim screen tmux

# Install python dev toots for easy_install	
RUN	sudo apt-get install -yqq python-setuptools python-dev build-essential
	
# Install pip	
RUN sudo easy_install pip

# Install airflow
RUN sudo pip install apache-airflow && \
    airflow initdb

	
RUN sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo rm -rf /tmp/*

RUN sudo wget -qO - ${SCALA_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/ && \
    sudo wget -qO - ${MAVEN_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/  && \
    sudo wget -qO - ${SPARK_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/ && \
    sudo wget -qO - ${CONFLUENT_KAFKA_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/ && \
    sudo wget -qO - ${CASSANDRA_BINARY_DOWNLOAD_URL} | sudo tar -xz -C /usr/local/ && \
    cd /usr/local/ && \
	sudo chown -R hduser:hduser ${SCALA_BINARY_ARCHIVE_NAME} && \
	sudo chown -R hduser:hduser ${MAVEN_BINARY_ARCHIVE_NAME} && \
	sudo chown -R hduser:hduser ${SPARK_BINARY_ARCHIVE_NAME} && \
	sudo chown -R hduser:hduser ${CONFLUENT_KAFKA_BINARY_ARCHIVE_NAME} && \
	sudo chown -R hduser:hduser ${CASSANDRA_BINARY_ARCHIVE_NAME} && \
    sudo ln -s ${SCALA_BINARY_ARCHIVE_NAME} scala && \
    sudo ln -s ${MAVEN_BINARY_ARCHIVE_NAME} maven && \
    sudo ln -s ${SPARK_BINARY_ARCHIVE_NAME} spark && \
    sudo ln -s ${CONFLUENT_KAFKA_BINARY_ARCHIVE_NAME} kafka && \
    sudo ln -s ${CASSANDRA_BINARY_ARCHIVE_NAME} cassandra && \
	sudo chown  hduser:hduser scala && \
	sudo chown  hduser:hduser maven && \
	sudo chown  hduser:hduser spark && \
	sudo chown  hduser:hduser kafka && \
	sudo chown  hduser:hduser cassandra &&\
    cp spark/conf/log4j.properties.template spark/conf/log4j.properties

# Configure env variables for Scala, SBT and Spark.
# Also configure PATH env variable to include binary folders of Java, Scala, SBT and Spark.
ENV SCALA_HOME  /usr/local/scala
ENV MAVEN_HOME  /usr/local/maven
ENV SPARK_HOME  /usr/local/spark
ENV KAFKA_HOME /usr/local/kafka
ENV CASSANDRA_HOME /usr/local/cassandra

ENV PATH   $JAVA_HOME/bin:$SCALA_HOME/bin:$MAVEN_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$KAFKA_HOME/bin:$CASSANDRA_HOME/bin:$PATH

# Expose ports for monitoring.
# SparkContext web UI on 4040 -- only available for the duration of the application.
# Spark master’s web UI on 8080.
# Spark worker web UI on 8081.
# Spark Rest 7077 and 6066
# Airflow WebServer and other ports 8090 5555 8793
# Springboot Dashboard 8070
EXPOSE 4040 8080 8081 7077 6066 2181 9092 9042  8070 8090 5555 8793	
	
CMD ["/bin/bash"]	