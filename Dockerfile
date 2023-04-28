FROM amazoncorretto:8u342 AS build

USER root

RUN yum install -y tar which gzip \
  && rm -rf /var/cache/yum/* \
  && yum clean all

ARG MAVEN_VERSION=3.8.6
ARG SHA=f790857f3b1f90ae8d16281f902c689e4f136ebe584aba45e4b1fa66c80cba826d3e0e52fdd04ed44b4c66f6d3fe3584a057c26dfcac544a60b301e6d0f91c26
ARG BASE_URL=https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# The following ARG and 2 LABEL are used by Jenkinsfile command
# to identify this intermediate container, for extraction of
# code coverage and other reported values.
ARG build
LABEL build=${build}
LABEL image=build


COPY / /usr/src/app

RUN mvn --no-transfer-progress -f /usr/src/app/pom.xml clean install -DskipTests
#-s /usr/src/app/settings.xml

# ARG DOCKER_TAGS=latest
# ARG DOCKER_IMAGE_NAME=graph-quilt/graphql-gateway:${DOCKER_TAGS}


FROM amazoncorretto:8u342

USER root

RUN yum install -y shadow-utils && yum clean all
RUN groupadd appuser
RUN useradd -m -s /bin/bash -g appuser appuser

COPY --from=build /usr/src/app/target/graphql-gateway-java.jar /opt/graphql-gateway-java.jar
COPY --from=build /usr/src/app/run.sh /opt/run.sh
RUN chmod 644 /opt/graphql-gateway-java.jar

RUN chown -R appuser:appuser /opt
USER appuser

RUN mkdir /opt/conf
RUN chown appuser:appuser /opt -R

WORKDIR /opt

ENTRYPOINT ["/opt/run.sh"]

CMD ["--containerized"]