FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y curl jq software-properties-common

RUN add-apt-repository ppa:kelleyk/emacs && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y emacs26

RUN rm -rf /var/lib/apt/lists/* && \
    apt-get purge --auto-remove && \
    apt-get clean

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
