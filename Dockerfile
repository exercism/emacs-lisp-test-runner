FROM silex/emacs:30.1

RUN apt-get update && \
    apt-get install -y curl jq software-properties-common

RUN rm -rf /var/lib/apt/lists/* && \
    apt-get purge --auto-remove && \
    apt-get clean

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
