FROM centos:7
MAINTAINER Benjamin Doran (benjamindoran@g.harvard.edu)

## SETUP
RUN yum upgrade \
  && yum -y install https://centos7.iuscommunity.org/ius-release.rpm \
  && yum -y install python36u python36u-pip \
  && pip3.6 install py4j pyspark \
  && adduser sparkuser \
  && yum -y remove yum-utils ius-release epel-release \
  && yum clean all && rm -rf /var/cache/yum

## many commands below this point taken from:
# https://hub.docker.com/r/gettyimages/spark/~/dockerfile/
##

## ENABLE PYTHON3
# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYSPARK_PYTHON=python3.6 \
  PYTHONHASHSEED=0 \
  PYTHONIOENCODING=UTF-8 \
  PIP_DISABLE_PIP_VERSION_CHECK=1

## JAVA
ARG JAVA_MAJOR_VERSION=8
ARG JAVA_UPDATE_VERSION=131
ARG JAVA_BUILD_NUMBER=11
ENV JAVA_HOME=/usr/jdk1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}
ENV PATH=$PATH:${JAVA_HOME}/bin

RUN curl -sL --retry 3 --insecure \
  --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMBER}/d54c1d3a095b4ff2b6607d096fa80163/server-jre-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz" \
  | gunzip \
  | tar x -C /usr/ \
  && ln -s $JAVA_HOME /usr/java \
  && rm -rf $JAVA_HOME/man

## HADOOP
ENV HADOOP_VERSION=2.7.3
ENV HADOOP_HOME=/usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop \
  PATH=$PATH:${HADOOP_HOME}/bin
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

## SPARK
ENV SPARK_VERSION=2.2.0
ENV SPARK_PACKAGE=spark-${SPARK_VERSION}-bin-without-hadoop \
  SPARK_HOME=/usr/spark-${SPARK_VERSION}
ENV PATH=$PATH:${SPARK_HOME}/bin \
  SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*" 
RUN curl -sL --retry 3 \
  "http://d3kbcqa49mib13.cloudfront.net/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME \
 && ln -s $SPARK_HOME /usr/spark

## FINISH IMAGE
WORKDIR /home/sparkuser
CMD ["/usr/spark/bin/spark-class", "org.apache.spark.deploy.master.Master"]



