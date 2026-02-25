# ---------------------------
# Stage 1: Builder
# ---------------------------
FROM sbtscala/scala-sbt:eclipse-temurin-21.0.8_9_1.12.0_3.3.7@sha256:ef358174f9787f888cfb1d11725512ac83f677fb2b37261402350cacb9803de8 AS builder

# Arguments (warm-up)
ARG SCALA_VERSION=3.3.7

USER sbtuser
WORKDIR /home/sbtuser/app

# Warm sbt cache
RUN set -eux; \
    mkdir -p project; \
    echo "scalaVersion := \"${SCALA_VERSION}\"" > build.sbt; \
    echo "sbt.version=1.12.0" > project/build.properties; \
    echo "case object Temp" > Temp.scala; \
    sbt -batch compile; \
    rm -rf project build.sbt Temp.scala target

# ---------------------------
# Stage 2: Dev image
# ---------------------------
FROM eclipse-temurin:21-jdk-noble@sha256:efec1fca48fed530d4727c1ecd9c48d955153bad24067ee43ccf55e6e0d727c7

USER ubuntu
ENV HOME=/home/ubuntu

# Copy sbt cache from builder
#COPY --from=builder /home/sbtuser/.ivy2 $HOME/.ivy2
COPY --from=builder /home/sbtuser/.cache/coursier $HOME/.cache/coursier

# Working directory & volume
WORKDIR $HOME/app
VOLUME $HOME/app

ENV JAVA_OPTS="-Xms1G -Xmx2G"

# Expose ports
EXPOSE 9000 5005
# Dev entrypoint
ENTRYPOINT ["sbt", "-Dhttp.address=0.0.0.0", "-Dconfig.file=/home/ubuntu/app/conf/development.conf"]
CMD ["run"]
