FROM silex/emacs:30.1-alpine

RUN apk update && \
    apk add curl \
            jq \
            bash \
            python3 \
            util-linux

RUN rm /var/cache/apk/*

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
