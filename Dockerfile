FROM amazoncorretto:8u332 AS build

USER root

# The following ARG and 2 LABEL are used by Jenkinsfile command
# to identify this intermediate container, for extraction of
# code coverage and other reported values.
ARG build
LABEL build=${build}
LABEL image=build


COPY / /usr/src/app

RUN mvn -f /usr/src/app/pom.xml -s /usr/src/app/settings.xml clean install

FROM docker.intuit.com/dev/integration/cg-sre-services/service/base_cg_java:3.7.0

ARG DOCKER_TAGS=latest
ARG DOCKER_IMAGE_NAME=docker.intuit.com/data-dataportal/intuit-data-api/service/intuit-data-api:${DOCKER_TAGS}
ARG SERVICE_LINK=https://devportal.intuit.com/app/dp/resource/7425327477933316517

# Switch to root for installation and some other operations
USER root

COPY --from=build /usr/src/app/target/data-api.jar /opt/service.jar
RUN chmod 644 /opt/service.jar

RUN chown appuser:appuser /opt/service.jar
USER appuser
RUN mkdir /app/tmp
RUN mkdir /opt/conf
RUN chown appuser:appuser /app -R
