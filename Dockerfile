FROM alpine:3.9

LABEL maintainer="Michael Fessenden <michael@mikefez.com>"

ENV SSH_PRIVATE_KEY=
ENV GIT_REPO=
ENV REPO_BRANCH="master"
ENV LAUNCH_CMD="sh launch.sh"
ENV UPDATE_METHOD="FILE"
ENV GIT_LOCAL_FOLDER="/opt/local_repository"
ENV ADDITIONAL_APK=
ENV SECONDS_BETWEEN_CHECKS="30"
ENV PUID="1000"
ENV PGID="1000"

ENTRYPOINT ["/bin/sh", "-c", " \
    if [[ -z \"$GIT_REPO\" ]]; then echo \"ERROR: GIT_REPO is not set! Configure it and redeploy the container.\" && tail -f /dev/null; fi && \
    if [[ -z \"$LAUNCH_CMD\" ]]; then echo \"ERROR: LAUNCH_CMD is not set! Configure it and redeploy the container.\" && tail -f /dev/null; fi && \
    if [[ \"$UPDATE_METHOD\" != \"FILE\" ]] && [[ $UPDATE_METHOD != \"RESTART\" ]]; then echo \"ERROR: UPDATE_METHOD as ${UPDATE_METHOD} is not a valid option! Set it to \"ENV\" or \"RESTART\" and redeploy the container.\" && tail -f /dev/null; fi && \
    \
    \
    echo \"===== Container ENV Configuration =====\" && \
    echo \"!!!!! Ensure container is configured with \"restart: unless-stopped\" and redeploy if not already !!!!!\" && \
    if ! [[ -z \"$SSH_PRIVATE_KEY\" ]]; then echo \"SSH_PRIVATE_KEY has been provided\"; else echo \"SSH_PRIVATE_KEY has not provided\"; fi && \
    echo \"UPDATE_METHOD is ${UPDATE_METHOD}\" && \
    echo \"GIT_REPO is ${GIT_REPO}\" && \
    echo \"REPO_BRANCH is ${REPO_BRANCH}\" && \
    echo \"LAUNCH_CMD is ${LAUNCH_CMD}\" && \
    echo \" \" && \
    \
    /usr/sbin/groupadd -g ${PGID} container_group ; \
    /usr/sbin/useradd -s /bin/sh -g ${PGID} -u ${PUID} container_user ; \
    echo \"builder ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers ; \
    su container_user && \
    \
    \
    echo \"===== Startup Tasks =====\" && \
    if ! [[ -z \"$ADDITIONAL_APK\" ]]; then \
        echo \"Preparing to add additional apk [${ADDITIONAL_APK}]\" && \
        clean_list=$( echo \"${ADDITIONAL_APK}\" | tr ',' ' ') && \
        echo \"CMD: apk add --no-cache ${clean_list}\" && \
        apk add --no-cache ${clean_list} ; \
    fi && \
    mkdir -p ${GIT_LOCAL_FOLDER} && \
    cd ${GIT_LOCAL_FOLDER} && \
    rm -f /GIT_UPDATE_DETECTED /GIT_COMMITS /TASK_SUBPROCESS_PID && \
    if ! [[ -z \"$SSH_PRIVATE_KEY\" ]]; then \
        if ! [[ -f /root/.ssh/id_rsa ]]; then \
            echo \"Configuring system to use provided SSH key\" && \
            mkdir -p /root/.ssh/ && \
            echo -e ${SSH_PRIVATE_KEY} > /root/.ssh/id_rsa && \
            echo \"StrictHostKeyChecking no\" >> /root/.ssh/config && \
            chmod 400 /root/.ssh/id_rsa ; \
        else \
            echo \"Provided SSH key has already been configured\" ; \
        fi ; \
    fi && \
    \
    \
    echo \"Checking if ${GIT_REPO} exists in ${GIT_LOCAL_FOLDER}\" && \
    if [ -d .git ]; then \
        echo \"Repo exists locally, performing a hard reset & pulling\" && \
        git reset --hard && git pull ; \
    else \
        echo \"Repo does not exist locally, preparing to clone git repository at ${GIT_REPO} to ${GIT_LOCAL_FOLDER}\" && \
        git clone ${GIT_REPO} ${GIT_LOCAL_FOLDER} || (echo \" \" && echo \" \" && echo \"ERROR: Clone Failed. Make corrections and restart container\" && tail -f /dev/null) ;  \
    fi && \
    echo \"Creating /GIT_COMMITS file for versioning if needed\" && \
    git rev-list --count HEAD > /GIT_COMMITS && \
    chmod -R 755 /GIT_COMMITS && \
    echo \"Executing chmod -R 755 ${GIT_LOCAL_FOLDER}\" && \
    chmod -R 755 ${GIT_LOCAL_FOLDER} && \
    \
    \
    echo \"Executing LAUNCH_CMD as a background process: ${LAUNCH_CMD}, then capturing PID to file\" && \
    (${LAUNCH_CMD} & echo $! > /TASK_SUBPROCESS_PID && chmod -R 755 /TASK_SUBPROCESS_PID && echo \"Created /TASK_SUBPROCESS_PID containing subprocess PID\") && \
    while ! [[ -f /TASK_SUBPROCESS_PID ]]; do sleep 1; done && \
    echo \"Attempting to load /TASK_SUBPROCESS_PID to variable in main shell\" && \
    TASK_SUBPROCESS_PID=`cat /TASK_SUBPROCESS_PID` && \
    echo \"Background PID reported as: ${TASK_SUBPROCESS_PID}\" && \
    \
    \
    echo \"Startup tasks complete, entering shell update monitor loop\" && \
    echo \" \" && echo \" \" && \
    while true; do \
        if [[ $(git ls-remote origin -h refs/heads/${REPO_BRANCH} | awk '{print $1;}') != $(git rev-parse ${REPO_BRANCH}) ]]; then \
            if [[ \"$UPDATE_METHOD\" == \"RESTART\" ]]; then \
                echo \"[SHELL UPDATE MONITOR] New commit detected! Killing container via exit of PID 1- ensure restart: unless-stopped is enabled!\" ; \
                exit ; \
            else \
                echo \"[SHELL UPDATE MONITOR] New commit detected! Ending monitor, setting GIT_UPDATE_DETECTED file & waiting for background task to exit\" && \
                touch /GIT_UPDATE_DETECTED && \
                while ! [[ -z \"$( ps -p ${TASK_SUBPROCESS_PID} -o pid= )\" ]]; do sleep 1; done && \
                echo \"[SHELL UPDATE MONITOR] Background task exited, killing container via exit of PID 1\" && \
                exit ; \
            fi; \
        fi; \
        sleep ${SECONDS_BETWEEN_CHECKS}; \
    done"]

RUN apk update && \
    apk add --no-cache curl git nano mc htop psmisc openssh python3 procps shadow && \
    pip3 install virtualenv
