# Preludian Jenkins Docker in Docker

Simple tool to install and run a Jenkins Docker-in-Docker for your computer or a production server.

# What is Docker-in-Docker?

Docker-in-Docker is an initiative to use a Dockerized version of Docker with the Jenkins container being able to see the host docker socket, manipulating it.
The main objective is to keep Jenkins as a clean, but battle tested for any kind of build, with any technology/version.

Suppose that you need to create a job that builds a Java 1.6 application. With this approach you just need to create a docker container which runs Java 1.6 instead of letting jenkins handle this for you by using the Jenkins Docker pipelines.
But the thing is: ok, I have a Jenkins job, but how can I look inside the workspace and how to instantiate a new job and have my workspace visible inside the new container?

The answer is on the container itself. You must ensure that the /var/jenkins\_home will be accessible inside your container. For expliciting this /var/jenkins\_home inside the container the jenkins itself will chdir into the correct place, making your workspace folder visible inside the container;

# What do we have in the box?

We have a ready to use Jenkins with latest version of the war file and a bunch of plugins installed.

# How to install it?

To use this project you must have a docker installed. I tested with the latest available version so far: Docker CE 18+, but it might work on previous versions as well.

In a nutshell, to install a jenkins server you must clone this repo, then run the following command:

```
DOCKER_PREFIX=my_brand_new_jenkins DOCKER_PROJECT_PORT=8080 ./jenkins_deployment.sh install
```

## Params

In order to create an automated installation, I used the environment variables approach;
You must set the following params:

* DOCKER\_PREFIX - will be the name of your project;
* DOCKER\_PROJECT\_PORT - It will be the port number that I will use to export your jenkins to the Docker host;
* DOCKER\_AUTOYES - if set as 1 all prompts will be assumed as Yes, useful for automated environments;

## What happens behind the stage?

It will, in a nutshell:

1. Create the docker volumes for Jenkins home and Jenkins core;
2. Pull the Jenkins image and RUN;
3. Create a container mounting the volumes previously created with the docker mountpoint;
4. Skipping the initial Jenkins installation, proceeding to install the plugins automatically;
5. Performing a preflight check;
6. Sending you your admin password so you will being able to use your brand new Jenkins!


# Uninstalling

To uninstall it's pretty simple. Just trigger the following command:

```
DOCKER_PREFIX=my_brand_new_jenkins DOCKER_PROJECT_PORT=8080 ./jenkins_deployment.sh uninstall
```

This command will remove both jenkins container, and their associated images;


# Contribute!

Feel free to raise a pull request or an issue! It's made with pure bash script in order to be as more compatible as possible.
This is an ugly version of the script, but it is functional. I promisse to enhance it with the time and the adoption of more users.

Thank you and enjoy!
