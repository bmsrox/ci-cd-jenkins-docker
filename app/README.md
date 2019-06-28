#APP EXAMPLE

#### Edit Jenkinsfile

1. Edit the variable ``` serverNames ``` with the same names defined in SERVERNAME in docker-compose.yml of the ``` swarm-client ``` directory

2. Edit the ``` APP_NAME ```, ``` BIND_PORT ```

3. Edit ``` REGISTRY_REPO ``` for the Registry name where the containers will be stored

#### Edit proxy_reverse.conf file

    upstream app {
        server <container name here>:<container port here>;
    }

Use the same configuration of APP_NAME and BIND_PORT