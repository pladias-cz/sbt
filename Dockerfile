FROM sbtscala/scala-sbt:eclipse-temurin-21.0.8_9_1.12.0_3.3.7@sha256:ef358174f9787f888cfb1d11725512ac83f677fb2b37261402350cacb9803de8

ARG SCALA_VERSION=3.3.7
ARG JAVA_OPTS="-Xms1G -Xmx2G"
ENV HOME=/home/ubuntu

EXPOSE 9000 5005

# Working directory & volume
WORKDIR $HOME/app
VOLUME $HOME/app

USER root

RUN apt update
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
RUN apt install -y nodejs

RUN chown -R ubuntu:ubuntu $HOME # ~/.cache is somehow owned by root

# Warm sbt cache
USER ubuntu
RUN set -eux; \
    mkdir -p project; \
    echo "scalaVersion := \"${SCALA_VERSION}\"" > build.sbt; \
    echo "sbt.version=1.12.0" > project/build.properties; \
    echo "case object Temp" > Temp.scala; \
    sbt -batch compile; \
    rm -rf project build.sbt Temp.scala target

# Dev entrypoint
ENTRYPOINT ["sbt", "-Dhttp.address=0.0.0.0", "-Dconfig.file=/home/ubuntu/app/conf/development.conf"]
# "clean update run"
CMD ["run"]
