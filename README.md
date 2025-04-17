# dind_maker
A convenient tool to create Docker-in-Docker(DinD) with Makefile.

## Preface
The simplest way to implement DinD is to mount `/var/run/docker.sock` when running the container. Although Docker CLI is already very convenient, sometimes you still need to manually enter commands to verify certain things, such as whether an image has been built or whether a container is running. `dind_maker` provides a higher level way to run the DinD container with Makefile. It will check several things for you before and after creating images or containers. 

## Prerequisites
### Docker
Please refer to [dockerdocs - Install Docker Engine](https://docs.docker.com/engine/install/) to install Docker.

### GNU Make
If `make` is not installed, run:  
```bash
$ sudo apt-get udapte
$ sudo apt-get install make
$ make --version
```

## Note
**Root privilege**  
The root privilege is needed to start a new docker daemon.

## Platform
`dind_maker` is not well tested but has been applied to my personal projects on `Debian 10`, `Ubuntu 22.04`, and `Ubuntu 24.04`.

## Usage
Assume `Template` is a project that requires Docker to build and run; building `Template` requires installing some necessary packages, but we don't want to pollute the host's package dependencies. Instead, we want to create a Docker container, install the necessary packages inside this container, and then run Docker within the container to build and run the project. At this point, `dind_maker` can quickly help you set up DinD.

**Start a new docker daemon**  
First, start a new and separate docker daemon:  
```bash
$ make docker_daemon_start
```

To check whether the daemon runs correctly:  
```bash
$ make docker_daemon_check
```

**Build the Docker image**
If the daemon check is okay, build the image for the first time:  
```bash
$ make docker_build
```

If the image has been built (and not being removed), call:  
```bash
$ make docker_rebuild
```
or always call `docker_rebuild` is okay.

**Run the Docker container**  
After building the image, run the container with:  
```bash
$ make docker_run
```

**At the end**  
Once you're done using `dind_maker`, remember to stop and clean all the things:  
```bash
$ make docker_remove
$ make docker_daemon_stop
```
`docker_daemon_stop` not only stops the daemon but also deletes the data root. If DinD will be reused next time, one should not call `docker_daemon_stop` to keep the daemon alive.  
In fact, one still can call `docker_daemon_stop` and the data root can be deleted; it just takes more time to recreate the DinD next time.

## Contributions
**More isolated environment**  
`dind_maker` starts a new Docker daemon, creating new Docker host, pid file, and data root directory. It is fully separate from the default Docker daemon. 

**Check automatically before and after building or running**  
It will check a command can be executed correctly for you. For example, when you call `make docker_run` to run a container, it will first check whether an image is built and whether a container is running. Based on these status, `docker_run` will determine which actions to take. If the image hasn't been built, it will first build for you and then run the container.

**Recursive DinD**  
If someone wants to create the DinD container recursively(though it is less useful), one can create the new daemon with `make docker_daemon_start` only for the first time; and then recursively call `make docker_build` and `make docker_run`. In fact, this is possible because we always mount `/var/run/docker.sock` and export the environment variable `DOCKER_HOST=unix:///var/run/docker.sock` when running the container.

## Wiki
Some advanced usage or configurations can be achieved. Please refer to the [Wiki](https://github.com/luckykk273/dind_maker/wiki).

## Reference
1. [dockerdocs - Install Docker Engine](https://docs.docker.com/engine/install/)
2. [Docker-in-Docker: Containerized CI Workflows](https://www.docker.com/resources/docker-in-docker-containerized-ci-workflows-dockercon-2023/)
3. [~jpetazzo/Using Docker-in-Docker for your CI or testing environment? Think twice.](https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/)
4. [dockerdocs - Run in detached mode](https://docs.docker.com/guides/golang/run-containers/#run-in-detached-mode)
5. [dockerdocs - Understand how CMD and ENTRYPOINT interact](https://docs.docker.com/reference/dockerfile/#understand-how-cmd-and-entrypoint-interact)
