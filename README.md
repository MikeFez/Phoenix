# Phoenix
Like a Phoenix from the ashes, this container is designed to shut down upon detecting new commits in the remote branch of a repository, causing it to restart (immediately, or when ready) and pull said changes.

The idea is that upon start, the container will populate the ~/.ssh/id_rsa file with an ENV provided private SSH key, and then checkout a branch (master by default) of a git repository if it does not exist, or pull if it does. Once the repository is up to date, a provided command is executed as a background task within the local repository. This can be the execution of a shell script, launch of a python script, or scheduling of a cron task - anything. Once that script is launched in the background, PID 1 continues on to periodically check if there had been new commits made on the remote repo. If so, it does one of two configured options - either shuts the machine down immediately, or creates the file /GIT_UPDATE_DETECTED. Existence of this file as an indicator of pending updates within the script being executed in the background branch can be used to start a shutdown procedure, commit changed files, or anything else. Once the script exits (having the background process exit), PID will exit immediately, causing the container to shutdown & restart if configured properly, and performing git pull on the repository to get it up to date.

## Parameters

| Parameter | Function |
| :----: | --- |
| `-e GIT_REPO=git@github.com:MikeFez/Phoenix.git` | Required, Url to the remote git repository to be checked out, which contains the script to be ran & updated. |
| `-e LAUNCH_CMD=sh launch.sh` | Command to be executed (as a background process) in the local branches directory, once updated. Can be anything - _python3 app.py_, _sh launch.sh_, etc. |
| `-e SSH_PRIVATE_KEY=XXXXXX` | Optional, empty by default. This is the private SSH key that is redirected to ~/.ssh/id_rsa if the file does not already exist. Should be used if authentication with git repo is required. As this should be a single line, replace any line breaks with \n. Typically should be stored in docker-compose .env file.  |
| `-e REPO_BRANCH=master` | Optional, master by default. The branch that should be checked out and monitored for new commits. |
| `-e GIT_LOCAL_FOLDER=/opt/local_repository` | Optional, /opt/local_repository by default. This is the folder which the git repository is downloaded to, and the LAUNCH_CMD shall execute in. |
| `-e UPDATE_METHOD=FILE` | Optional, FILE by default. Options are "FILE", or "RESTART". This controls what happens should new commits be detected in the repository. _RESTART_ causes the container to immediately shut down (and restarted if configured properly), _FILE_ places an empty file named GIT_UPDATE_DETECTED on the root of the container. This can be used to wrap up the script being executed, which upon exit, will restart the container. |
| `-e SECONDS_BETWEEN_CHECKS=30` | Optional, 30 by default. The number of seconds to wait in between checks for new commits. |

## docker-compose example

```
---
version: "3"
services:
  custom-script-phoenix-will-manage:
    image: mikefez/Phoenix
    container_name: custom-script-phoenix-will-manage
    environment:
      - SSH_PRIVATE_KEY # Should be set in .env file, but can be directly provided if needed.
      - GIT_REPO=git@github.com:MikeFez/Phoenix.git
      - LAUNCH_CMD=sh launch.sh # Optional, given that a file named launch.sh is in the GIT_REPO
      - REPO_BRANCH=master  # Optional
      - GIT_LOCAL_FOLDER=FILE  # Optional
      - UPDATE_METHOD=FILE  # Optional
    volumes:  # Volumes are not required, but can be added if you'd like the container's time to match the host machine
      - /etc/localtime:/etc/localtime:ro 
      - /etc/timezone:/etc/timezone:ro
    restart: unless-stopped  # This should be enabled to ensure the container restarts, updating upon start again
```
