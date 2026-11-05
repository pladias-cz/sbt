FROM sbtscala/scala-sbt:eclipse-temurin-25.0.5_8_1.13.1_3.3.9@sha256:576e29b2ef93c863fd1c9bf4b6d793f11321aa8a9b6899e64d54bd414b7cc028

ARG SCALA_VERSION=3.3.9
ARG SBT_VERSION=1.13.1
ARG JAVA_OPTS="-Xms1G -Xmx2G"
ENV HOME=/home/ubuntu

EXPOSE 9000 5005

# Working directory & volume
WORKDIR $HOME/app
VOLUME $HOME/app

USER root

RUN chown -R ubuntu:ubuntu $HOME # ~/.cache is somehow owned by root

RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Warm sbt cache
USER ubuntu
RUN set -eux; \
    mkdir -p project; \
    echo "scalaVersion := \"${SCALA_VERSION}\"" > build.sbt; \
    echo "sbt.version=${SBT_VERSION}" > project/build.properties; \
    echo "case object Temp" > Temp.scala; \
    sbt -batch compile; \
    rm -rf project build.sbt Temp.scala target

# Debug options
ENV JAVA_OPTS="-Xms2G -Xmx2G -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"

# Dev entrypoint
ENTRYPOINT ["sbt", "-Dhttp.address=0.0.0.0", "-Dconfig.file=/home/ubuntu/app/conf/development.conf"]
# "clean update run"
CMD ["run"]
