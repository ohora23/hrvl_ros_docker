#!/bin/bash
XSOCK=/tmp/.X11-unix

docker run -it \
	--gpus all\
	--network=host\
	--privileged \
	--volume=$XSOCK:$XSOCK:rw \
	--volume=${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
	--volume="/home/$USER:/home/ros/$USER"\
	--volume="/media:/media:rw" \
	--volume="/dev:/dev:rw" \
	--volume="/sys:/sys:rw" \
	--group-add $(getent group audio | cut -d: -f3) \
	--device /dev/snd \
	--device /dev/dri \
	--env="PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native" \
	--env="DISPLAY=${DISPLAY}" \
	--volume="$HOME/.Xauthority:/home/ros/.Xauthority:rw"\
	$1
