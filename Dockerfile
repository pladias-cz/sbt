FROM eclipse-temurin:8-jdk-noble@sha256:441090c84ef7336dce4fcf3a8877bffc1bf52cadb856327f371828ac84ae6d79

# Arguments / environment
ARG SCALA_VERSION=2.13.3
ARG SBT_VERSION=1.3.12
ENV SCALA_VERSION=${SCALA_VERSION}
ENV SBT_VERSION=${SBT_VERSION}

# Install system deps
RUN apt-get update && \
    apt-get install -y curl gnupg apt-transport-https rpm && \
    rm -rf /var/lib/apt/lists/*

## Install sbt from official repo - not available for such old version as 1.3
#RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" > /etc/apt/sources.list.d/sbt.list && \
#    curl -sL https://keyserver.ubuntu.com/pks/lookup?op=get\&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823 | apt-key add && \
#    apt-get update && \
#    apt-get install -y sbt=${SBT_VERSION} && \
#    rm -rf /var/lib/apt/lists/*

# Install sbt 1.3.12 manually
RUN curl -L -o sbt.tgz https://github.com/sbt/sbt/releases/download/v1.3.12/sbt-${SBT_VERSION}.tgz && \
    tar -xvzf sbt.tgz -C /usr/local && \
    rm sbt.tgz && \
    ln -s /usr/local/sbt/bin/sbt /usr/local/bin/sbt

# Install Scala
RUN curl -fsL https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz | tar xfz - -C /usr/share && \
    mv /usr/share/scala-${SCALA_VERSION} /usr/share/scala && \
    ln -s /usr/share/scala/bin/scala /usr/local/bin/scala && \
    ln -s /usr/share/scala/bin/scalac /usr/local/bin/scalac

# Working directory
VOLUME /home/app
WORKDIR /home/app

# Warm sbt cache (fake project build)
RUN sbt sbtVersion && \
    mkdir -p project && \
    echo "scalaVersion := \"${SCALA_VERSION}\"" > build.sbt && \
    echo "sbt.version=${SBT_VERSION}" > project/build.properties && \
    echo "case object Temp" > Temp.scala && \
    sbt compile && \
    rm -rf project build.sbt Temp.scala target

# Expose ports
EXPOSE 9000 5005

# Debug options
ENV JAVA_OPTS="-Xms2G -Xmx2G -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"

# Entrypoint / CMD
ENTRYPOINT ["sbt", "-Dhttp.address=0.0.0.0", "-Dconfig.file=/home/app/conf/development.conf"]
CMD ["run"]
