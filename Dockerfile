FROM silex/emacs:30.1-alpine

RUN apk update && \
    apk add curl \
            jq \
            bash \
            python3 \
            util-linux && \
    rm /var/cache/apk/*

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
