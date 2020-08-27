#!/bin/bash
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

nvidia-docker run -it \
        --net host \
        --hostname=hrvl-AERO\
        --privileged=true \
        --volume=$XSOCK:$XSOCK:rw \
        --volume=$XAUTH:$XAUTH:rw \
        --volume=/home/hrvl:/home/ros/data:rw \
        --volume=${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
        --group-add $(getent group audio | cut -d: -f3) \
        --device /dev/snd \
        --device /dev/video0 \
        --env="PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native" \
        --env="XAUTHORITY=${XAUTH}" \
        --env="DISPLAY" \
        --env="UID=`id -u $who`" \
        --env="UID=`id -g $who`" \
	ohora23/hrvl_devel_env:latest_with_sound \
	@1


