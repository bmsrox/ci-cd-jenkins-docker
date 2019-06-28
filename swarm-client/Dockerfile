FROM docker:latest
RUN apk --update add openjdk8-jre openssh git \
    && wget -O swarm-client.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.9/swarm-client-3.9.jar

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
    && sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]