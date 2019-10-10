FROM alpine:3.9

LABEL maintainer="Michael Fessenden <michael@mikefez.com>"

ENV SSH_KEY=
ENV UPDATE_METHOD="env"
ENV GIT_REPOSITORY=
ENV STARTUP_SCRIPT=

ENTRYPOINT ["/bin/bash", "-c", " \
    if [[ -z $GIT_REPOSITORY ]]; then echo \"ERROR: GIT_REPOSITORY is not set! Configure it and restart the container.\" && tail -f /dev/null; fi && \
    if [[ -z $STARTUP_SCRIPT ]]; then echo \"ERROR: STARTUP_SCRIPT is not set! Configure it and restart the container.\" && tail -f /dev/null; fi && \
    if [[ $UPDATE_METHOD != \"ENV\" ]] && [[ $UPDATE_METHOD != \"RESTART\" ]]; then echo \"ERROR: UPDATE_METHOD as ${UPDATE_METHOD} is not a valid option! Set it to \"ENV\" or \"RESTART\" and restart the container.\" && tail -f /dev/null; fi && \
    \
    echo \"== Container ENV Configuration ==\" && \
    if ! [[ -z $SSH_KEY ]]; then echo \"SSH_KEY has been provided\"; echo \"SSH_KEY has not provided\"; fi && \
    echo \"UPDATE_METHOD is ${UPDATE_METHOD}\" && \
    echo \"GIT_REPOSITORY is ${GIT_REPOSITORY}\" && \
    echo \"STARTUP_SCRIPT is ${STARTUP_SCRIPT}\" && \
    echo \"Container started in ${REGION}, shell is ${SHELL}\" && \
    echo \"=============================\n\" && \
    echo \"== Startup Tasks ==\" && \
    echo \"Saving ENV Variables to /etc/environment for cron usage, if needed.\" && \
    printenv | grep -v \"no_proxy\" >> /etc/environment && \

    cd /home/qatester ; \
    echo \"Downloading updates from bwa.katalon.setup...\" && \
    wget -O \"setup.zip\" \"${BWA_KATALON_SETUP_REPO_URL}\" && \
    unzip -o setup.zip && \
    rm setup.zip && \
    chmod -R 755 bin && \
    echo \"Updates have been installed, updating crontab...\" && \
    service cron start && \
    ( crontab -l | grep -v -F \"${EXECUTION_TASK}\" ; echo \"${EXECUTION_SCHEDULE} ${EXECUTION_TASK} > /proc/1/fd/1 2> /proc/1/fd/2\n\" ) | crontab - && \
    echo \"Registered cron task ${EXECUTION_SCHEDULE} ${EXECUTION_TASK}\" && \
    mkdir /home/qatester/www_reports && cd www_reports && python3 -m http.server 80 &\
    echo \"Started Python http.server on port 80 to expose local reports\" && \
    tail -f /dev/null"]

RUN apk update && apk add --no-cache curl git nano htop psmisc