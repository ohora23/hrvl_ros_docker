#!/bin/bash
XSOCK=/tmp/.X11-unix

docker run -it \
        --hostname=hrvl-server \
        --gpus all \
        --user=$(id -u $USER):$(id -g $USER) \
        --workdir="/home/$USER" \
        --privileged=true \
        --volume=$XSOCK:$XSOCK:rw \
        --volume=${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
        --volume="/home/$USER:/home/$USER" \
        --volume="/etc/group:/etc/group:ro" \
        --volume="/etc/passwd:/etc/passwd:ro" \
        --volume="/etc/shadow:/etc/shadow:ro" \
        --volume="/etc/sudoers.d:/etc/sudoers.d:ro" \
        --group-add $(getent group audio | cut -d: -f3) \
        --device /dev/snd \
        --env="PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native" \
        --env="DISPLAY=${DISPLAY}" \
     ohora23/hrvl_devel_env:latest_with_sound

