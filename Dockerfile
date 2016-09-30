#
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#

FROM nimmis/java-centos:oracle-8-jre
MAINTAINER Adam Kunicki <adam@streamsets.com>

RUN yum -y install bash curl sed libstdc++ krb5-workstation which

ENV SDC_USER=sdc

# The paths below should generatelly be attached to a VOLUME for persistence
# SDC_DATA is a volume for storing collector state. Do not share this between containers.
# SDC_LOG is an optional volume for file based logs. You must provide a custom sdc-log4j.properties file to use this.
# SDC_CONF is where configuration files are stored. This can be shared.
# SDC_RESOURCES is where resource files such as runtime:conf resources and Hadoop configuration can be placed.
ENV SDC_DIST="/opt/streamsets-datacollector" \
    SDC_DATA=/data \
    SDC_LOG=/logs \
    SDC_CONF=/etc/sdc \
    SDC_RESOURCES=/resources
# STREAMSETS_LIBRARIES_EXTRA_DIR is where extra libraries such as JDBC drivers should go.
ENV STREAMSETS_LIBRARIES_EXTRA_DIR="${SDC_DIST}/libs-common-lib"

RUN groupadd ${SDC_USER} && \
  useradd -g ${SDC_USER} ${SDC_USER}

# ARG is new in Docker 1.9 and not yet supported by Docker Hub Automated Builds
# ARG SDC_VERSION
ENV SDC_VERSION ${SDC_VERSION:-2.0.0.0}

# Download the SDC tarball, Extract tarball and cleanup
RUN cd /tmp && \
  curl -O -L "https://archives.streamsets.com/datacollector/${SDC_VERSION}/tarball/streamsets-datacollector-all-${SDC_VERSION}.tgz" && \
  tar xzf "/tmp/streamsets-datacollector-all-${SDC_VERSION}.tgz" -C /opt/ && \
  rm -rf "/tmp/streamsets-datacollector-all-${SDC_VERSION}.tgz" && \
  mv "/opt/streamsets-datacollector-${SDC_VERSION}" "${SDC_DIST}"

# Log to stdout for docker instead of sdc.log for compatibility with docker.
RUN sed -i 's|DEBUG|INFO|' "${SDC_DIST}/etc/sdc-log4j.properties" && \
sed -i 's|INFO, streamsets|INFO, stdout|' "${SDC_DIST}/etc/sdc-log4j.properties"

# Create data directory and optional mount point
RUN mkdir -p "${SDC_DATA}" /mnt "${SDC_LOG}" "${SDC_RESOURCES}"

# Move configuration to /etc/sdc
RUN mv "${SDC_DIST}/etc" "${SDC_CONF}"

# Disable authentication by default, overriable with custom sdc.properties.
RUN sed -i 's|\(http.authentication=\).*|\1none|' "${SDC_CONF}/sdc.properties"

# Setup filesystem permissions
RUN chown -R "${SDC_USER}:${SDC_USER}" "${SDC_CONF}" "${SDC_DATA}" "${SDC_LOG}" "${SDC_RESOURCES}"

#RUN /opt/streamsets-datacollector/bin/streamsets stagelibs -install=streamsets-datacollector-apache-solr_6_1_0-lib,streamsets-datacollector-aws-lib,streamsets-datacollector-basic-lib,streamsets-datacollector-cassandra_3-lib,streamsets-datacollector-cdh_5_7-cluster-cdh_kafka_2_0-lib,streamsets-datacollector-cdh_5_7-lib,streamsets-datacollector-cdh_kafka_1_3-lib,streamsets-datacollector-cdh_kafka_2_0-lib,streamsets-datacollector-groovy_2_4-lib,streamsets-datacollector-jdbc-lib,streamsets-datacollector-jms-lib,streamsets-datacollector-jython_2_7-lib,streamsets-datacollector-omniture-lib,streamsets-datacollector-stats-lib

USER ${SDC_USER}
EXPOSE 18630
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["dc"]
