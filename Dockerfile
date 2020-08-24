# This Dockerfile is used to build an ROS + OpenGL + Gazebo + Tensorflow image based on Ubuntu 18.04
FROM nvidia/cudagl:10.1-devel-ubuntu18.04

LABEL maintainer "Prof. JKYOO @ HRVL, DJU"
ENV REFRESHED_AT 2020-08-21

# setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && apt-get install -q -y tzdata && rm -rf /var/lib/apt/lists/*

# Install packages without prompting the user to answer any questions
ENV DEBIAN_FRONTEND noninteractive

## CUDNN Runtime-packages
ENV CUDNN_VERSION 7.6.0.64
LABEL com.turlucode.ros.cudnn="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda10.1 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

## CUDNN Devel-packages
RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda10.1 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda10.1 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*


# Install sudo & applications
RUN apt-get update && \
    apt-get install -y sudo apt-utils curl dpkg grep sed git wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    terminator \
    fonts-nanum-coding \
    && rm -rf /var/lib/apt/lists/*

# Install cmake 3.15.5
RUN git clone https://gitlab.kitware.com/cmake/cmake.git && \
cd cmake && git checkout tags/v3.15.5 && ./bootstrap --parallel=8 && make -j8 && make install && \
cd .. && rm -rf cmake
# autoconf
RUN apt-get update && apt-get install -y automake autoconf pkg-config libevent-dev libncurses5-dev bison && \
apt-get clean && rm -rf /var/lib/apt/lists/*
# TUX
RUN git clone https://github.com/tmux/tmux.git && \
cd tmux && git checkout tags/3.1 && ls -la && sh autogen.sh && ./configure && make -j8 && make install


# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# set env vars
ENV ROS_DISTRO melodic
ENV ROS_PKG_VERSION 1.4.1-0*
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics


# Environment config
ENV DEBIAN_FRONTEND=noninteractive

# Add new sudo user
ARG user=ros
ARG passwd=ros
ARG uid=1000
ARG gid=1000
ENV USER=$user
ENV PASSWD=$passwd
ENV UID=$uid
ENV GID=$gid
RUN useradd --create-home -m $USER && \
        echo "$USER:$PASSWD" | chpasswd && \
        usermod --shell /bin/bash $USER && \
        usermod -aG sudo $USER && \
        echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USER && \
        chmod 0440 /etc/sudoers.d/$USER && \
        # Replace 1000 with your user/group id
        usermod  --uid $UID $USER && \
        groupmod --gid $GID $USER

### Install VScode
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

RUN sudo apt-get update && \
    sudo apt-get install -y code

### ROS and Gazebo Installation
# Install other utilities
RUN apt-get update && \
    apt-get install -y vim \
    tmux \
    git \
    wget \
    lsb-release \
    lsb-core \
    && rm -rf /var/lib/apt/lists/*

# Install ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list' && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt-get update && apt-get install -y ros-melodic-desktop-full && \
    apt-get install -y python-rosdep python-vcstools python-rosinstall && \
    rm -rf /var/lib/apt/lists/* && \
    rosdep init

# Install Gazebo
RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list' && \
    wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add - && \
    apt-get update && \
    apt-get install -y gazebo9 libgazebo9-dev && \
    apt-get install -y ros-melodic-gazebo-ros-pkgs ros-melodic-gazebo-ros-control

# ISSUE@20200821 : gazebo: symbol lookup error  --> Reason: ignition-math version is out of date
# Solution: as follows
RUN sudo apt upgrade -y libignition-math2


###################################################
USER $USER
WORKDIR /home/ros
# Set path to conda
ENV PATH /home/ros/anaconda3/bin:$PATH
# Anaconda Installing
RUN wget --quiet https://repo.continuum.io/archive/Anaconda3-2020.07-Linux-x86_64.sh
RUN bash Anaconda3-2020.07-Linux-x86_64.sh -b
RUN rm Anaconda3-2020.07-Linux-x86_64.sh 

# Updating Anaconda packages
RUN conda update conda
RUN conda update anaconda
RUN conda update --all

# Install pytorch
#RUN conda install pytorch torchvision cudatoolkit=10.1 -c pytorch

# Configuring access to Jupyter
RUN mkdir /home/ros/notebooks
RUN jupyter notebook --generate-config --allow-root
RUN echo "c.NotebookApp.password = u'sha1:6a3f528eec40:6e896b6e4828f525a6e20e5411cd1c8075d68619'" >> /home/ros/.jupyter/jupyter_notebook_config.py

# Terminator setting
RUN mkdir -p $HOME/.config/terminator
COPY configs/terminator_config /home/${user}/.config/terminator/config
#COPY entrypoint.sh /home/${user}/entrypoint.sh
#RUN sudo chmod +x /home/${user}/entrypoint.sh 
# && sudo chown ${user}:${user} /home/${user}/entrypoint.sh \
RUN sudo chown ${user}:${user} /home/${user}/.config/terminator/config 

#### If terminator fails use following
#eval `dbus-launch --auto-syntax` terminator


############################################################################
# Expose Jupyter 
EXPOSE 8888

# Expose Tensorboard
EXPOSE 6006

# Expose SSH
EXPOSE 22

############################################################################
### Switch to root user to install additional software
USER $USER

WORKDIR /home/ros
USER $USER
RUN rosdep fix-permissions && rosdep update
RUN echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"

# RUN Terminator 
#CMD ["terminator"]
