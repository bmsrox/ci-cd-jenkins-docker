## CI/CD environment using Docker Swarm and Jenkins for standalone applications

In this example I will use 3 environments, one of CI / CD Server (Jenkins / Portainer), a STAGING server and a PRODUCTION server.

### About the tools

Portainer:

    This service is for orchestrating docker containers

Jenkins:

    Continuous Integration Server and Continuous Delivery

### Directory Structure

    app/                contains an example application
    ci/                 contains the configuration of Jenkins and Portainer
    proxy/              contains the Dockerfile of NGINX for proxy
    swarm-client/       contains the configuration of Swarm Client

#### NOTE: Build all the containers before and configure the docker-compose.yml with their respective images

    ci/Dockerfile
    proxy/Dockerfile
    swarm-client/Dockerfile

### STEP 1: CONFIGURATION IN ALL SERVERS

Install DOCKER in all servers that will be part of the environment

    https://docs.docker.com/install/

Start docker swarm within each server

    docker swarm init --advertise-addr <SERVER IP>

### STEP 2: CONFIGURING SLAVE SERVERS (PROD, HML, etc)

The commands below must be run within each server.

#### On the servers that will host the containers, we must configure TCP communication (insecure way) by exposing the docker daemon port to PORTAINER to monitor the containers.

create a file in the directory:

    mkdir /etc/systemd/system/docker.service.d
    vim docker.conf

paste the following settings:

    [Service]
    ExecStart=
    ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock

and execute the commands below:

    systemctl daemon-reload
    systemctl restart docker

##### A secure way is to lock the docker daemon port by creating a firewall rule for only the CI / CD Server to see port 2375 from the other servers. Another safe way is using TLS

#### Creating docker secret

The command below create an user to access Jenkins Master

    echo '-master http://<JENKINS_ENDPOINT>:<PORT> -password <PASS_USER_SERVICE> -username <USER_SERVICE>'|docker secret create jenkins-master -

change the PASS_USER_SERVICE and USER_SERVICE to a valid login in Jenkins Master

#### Creating a Network

    docker network create --attachable --driver overlay <LAN NAME>

#### Configuring the Swarm Client

Inside the ``` swarm-client ``` directory, edit the file docker-compose.yml
changing the environment variable SERVERNAME of service ``` jenkins-agent ```:

Example:

    environment:
        SERVERNAME: <CLIENT_SERVER_NAME>

and run the command:

    docker stack deploy -c docker-compose.yml <CLIENT_SERVER_NAME>-swarm-client

#### NOTE: The same servername used in this step must be configured in the project JENKINSFILE file in the variable ``` serverNames ```

### STEP 3: CI / CD SERVER CONFIGURATION

#### Configuring SSH Keys

    ssh-keygen -t rsa -b 4096
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

Edit the file ``` ci/docker-compose.yml ``` and change HOST_PATH_SSH to where the SSH keys are

      jenkins:
        ...
          volumes:
            - <HOST_PATH_SSH>/.ssh:/home/jenkins/.ssh
        ...

Run the command to up Jenkins and Portainer

    docker stack deploy -c docker-compose.yml ci-env

#### Configuring Portainer to register endpoints

Edite o arquivo que esta em ``` ci/docker-compose.yml ```  novamente e adicione a configuração abaixo no serviço do Portainer:
Edit the file ``` ci/docker-compose.yml ``` again and add the configuration below in the Portainer service:

#### NOTE: This step should be done only once.

      portainer:
        ...
          command: -H tcp://<ONE_OF_CLIENT_SERVER_IP>:2375
        ...

run the command to update Portainer service:

    docker stack deploy -c docker-compose.yml ci-env

With this, PORTAINER will be able to identify one of the servers and it will be possible to configure others ENDPOINTs

### STEP 4: CONFIGURING JENKINS

#### JENKINS DEPENDENCE

Install plugin ``` Self-Organizing Swarm Plug-in Modules ```

#### CREDENTIALS

Create the credentials for the Registry (user / password) and for authentication on the bitbucket via SSH by copying the private key created in the step ``` Configuring SSH Keys ```
    
    http://<JENKINS_IP>/credentials/store/system/domain/_/newCredentials

#### CONFIGURING PIPELINE IN JENKINS

Use the APP example

#### Jenkinsfile

Edit the variable ``` serverNames ``` with the same names defined in SERVERNAME in docker-compose.yml of the ``` swarm-client ``` directory

Edit the APP_NAME, BIND_PORT
Edit REGISTRY_REPO for the registry name where the containers will be stored

#### Bitbucket configuration

#### NOTE: you can use github

Create a repository on bitbucket and copy the public key from the CI Server and add to Settings > Access Keys

and run the command to validate the keys:
    
    ssh -T git@bitbucket.org

Configure the ``` multi branch pipeline ```

#### ADDING ENDPOINTs IN PORTAINER

If TLS has been configured, inform the keys for PORTAINER to orchestrate the containers on CLIENT servers.

If the communication is via TCP, inform <HOST_IP>: <HOST_PORT> in the `` `Endpoint URL` `` field and save.

### REFERENCES

    https://github.com/krasi-georgiev/cd-demo/blob/master/Jenkinsfile
    
    https://medium.com/@maxy_ermayank/pipeline-as-a-code-using-jenkins-2-aa872c6ecdce

#### NOTE: Changelogs need to be implemented