# Phoenix
Dockerfile which checks out or pulls an existing repo on start, and then monitors for new commits. Restarts if new commits are found, updating the script.

## Parameters

| Parameter | Function |
| :----: | --- |
| `-e GIT_REPO=git@github.com:MikeFez/Phoenix.git` | Required, Url to the remote git repository to be checked out, which contains the script to be ran & updated. |
| `-e LAUNCH_CMD=sh launch.sh` | Command to be executed (as a background process) in the local branches directory, once updated. Can be anything - _python3 app.py_, _sh launch.sh_, etc. |
| `-e SSH_PRIVATE_KEY=XXXXXX` | Optional, empty by default. This is the private SSH key that is redirected to ~/.ssh/id_rsa if the file does not already exist. Should be used if authentication with git repo is required. As this should be a single line, replace any line breaks with \n. Typically should be stored in docker-compose .env file.  |
| `-e REPO_BRANCH=master` | Optional, master by default. The branch that should be checked out and monitored for new commits. |
| `-e GIT_LOCAL_FOLDER=/opt/local_repository` | Optional, /opt/local_repository by default. This is the folder which the git repository is downloaded to, and the LAUNCH_CMD shall execute in. |
| `-e UPDATE_METHOD=FILE` | Optional, FILE by default. Options are "FILE", or "RESTART". This controls what happens should new commits be detected in the repository. _RESTART_ causes the container to immediately shut down (and restarted if configured properly), _FILE_ places an empty file named GIT_UPDATE_DETECTED on the root of the container. This can be used to wrap up the script being executed, which upon exit, will restart the container. |

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
