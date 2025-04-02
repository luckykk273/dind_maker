# Set the base image
FROM ubuntu:latest

# Default build args to ensure Docker runs correctly
ARG PROJECT_DIR=/
ARG USER=user
ARG UID=1001
ARG GID=1001
ARG DOCKER_GID=999

# Install curl, sudo and apt-utils for minimum requirements to create a DinD container.
RUN apt-get update
# DEBIAN_FRONTEND=noninteractive  is needed for Debian systems.
# However, it doesn’t matter if we set it when using Ubuntu as the base image.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    sudo \
    vim \
    apt-utils

# Install Docker conveniently with the script.
RUN curl -fsSL https://get.docker.com -o get-docker.sh
RUN /bin/sh get-docker.sh

# Create Docker group which ID is the same as the one on the host.
# Note: because a simple Docker in Docker is used(connect the Docker daemon on the host),
#       we MUST ensure that the Docker GID is the same as the one on the host.
RUN if getent group ${DOCKER_GID} > /dev/null; then \
        CONFLICT_GROUP=$(getent group ${DOCKER_GID} | cut -d: -f1); \
        if ! getent group docker > /dev/null; then \
            groupadd docker; \
        fi; \
        EXISTING_DOCKER_GID=$(getent group docker | cut -d: -f3); \
        groupdel docker; \
        groupmod -g ${EXISTING_DOCKER_GID} ${CONFLICT_GROUP}; \
    fi && \
    groupadd -g ${DOCKER_GID} docker

# Create a user with the same UID, GID and add it to Docker group.

# If password is needed;
# RUN useradd -u ${UID} -G sudo ${USER} && \
#     echo "${USER}:user1234" | chpasswd

# By default, no password needed.
RUN useradd -u ${UID} -G sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER} && \
    usermod -aG docker ${USER}

# Explicitly create the directory `/home/<user>` and change its ownership so that
# the user can access it outside of `/home/<user>`.
RUN mkdir -p /home/${USER} && chown ${USER}:${USER} /home/${USER}

# Switch to the created user
USER ${USER}
WORKDIR ${PROJECT_DIR}

# Set the default shell
ENTRYPOINT [ "/bin/bash", "entrypoint.sh" ]
