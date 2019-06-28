## Ambiente de CI/CD usando Docker Swarm e Jenkins para aplicações standalone

Neste exemplo usarei 3 ambientes, sendo um de CI/CD Server (Jenkins/Portainer), um servidor de HOMOLOGAÇÃO e um servidor de PRODUÇÃO.

### Sobre as ferramentas

Portainer:

    Este serviço serve para orquestrar containers docker

Jenkins:

    Servidor de Integração contínua e Entrega contínua

### Estrutura de diretórios

    app/            contém um aplicativo de exemplo
    ci/             contém a configuração de Jenkins e Portainer
    proxy/          contém o Dockerfile do NGINX para proxy
    swarm-client/   contém a configuração do Swarm Client

#### OBS: Fazer o build de todos os container antes e configure os docker-compose.yml com suas respectivas imagens

    ci/Dockerfile
    proxy/Dockerfile
    swarm-client/Dockerfile

### PASSO 1: CONFIGURAÇÃO EM TODOS OS SERVIDORES

Instalar docker em todos os servidores que farão parte do ambiente

    https://docs.docker.com/install/

Iniciar o docker swarm 

    docker swarm init --advertise-addr <SERVER IP>

### PASSO 2: CONFIGURAÇÃO NOS SERVIDORES SLAVE (PROD,HML,etc)

Os comandos abaixo devem ser executados dentro de cada servidor.

#### Nos servidores que irão hospedar os containers, devemos configurar a comunicação via TCP (forma insegura) liberando a porta do daemon do docker para o PORTAINER monitorar os containers.

crie um arquivo no diretório:

    mkdir /etc/systemd/system/docker.service.d
    vim docker.conf

cole as seguintes configurações:

    [Service]
    ExecStart=
    ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock

e execute os comandos abaixo:

    systemctl daemon-reload
    systemctl restart docker

##### Uma forma segura, é bloquear a porta do daemon do docker, criando uma regra no firewall para apenas o Servidor de CI/CD ver a porta 2375 do outros servidores. Outra forma segura é usando TLS

#### Criando docker secret

O comando abaixo serve para criar um usuário para acessar o Jenkins Master

    echo '-master http://<JENKINS_ENDPOINT>:<PORT> -password <PASS_USER_SERVICE> -username <USER_SERVICE>'|docker secret create jenkins-master -

altere o PASS_USER_SERVICE e USER_SERVICE para um login valido no Jenkins Master

#### Criando uma rede

    docker network create --attachable --driver overlay bitlan

#### Configurando o Swarm CLient

Dentro do diretório ```swarm-client``` edite o arquivo docker-compose.yml 
alterando a variável de ambiente SERVERNAME do serviço ``` jenkins-agent ```:

Exemplo:

    environment:
        SERVERNAME: <NOME_SERVIDOR_CLIENT>

e execute o comando:

    docker stack deploy -c docker-compose.yml <NOME_SERVIDOR_CLIENT>-swarm-client

#### OBS: O mesmo nome de servidor utilizado neste passo deve ser configurado no arquivo JENKINSFILE do projeto na variável ``` serverNames ```

### PASSO 3: CONFIGURAÇÃO DO SERVIDOR DE CI/CD

#### Configurando Chaves SSH

    ssh-keygen -t rsa -b 4096
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

Edite o arquivo que esta em ``` ci/docker-compose.yml ``` e altere HOST_PATH_SSH para onde estão as chaves SSH

      jenkins:
        ...
          volumes:
            - <HOST_PATH_SSH>/.ssh:/home/jenkins/.ssh
        ...

Execute o comando para subir o Jenkins e o Portainer

    docker stack deploy -c docker-compose.yml ci-env

#### Configurando Portainer para cadastrar endpoints

Edite o arquivo que esta em ``` ci/docker-compose.yml ```  novamente e adicione a configuração abaixo no serviço do Portainer:

#### OBS: Este passo dever ser executando uma única vez.

      portainer:
        ...
          command: -H tcp://<ONE_OF_CLIENT_SERVER_IP>:2375
        ...

execute o comando para atualizar serviço do Portainer:

    docker stack deploy -c docker-compose.yml ci-env

Com isso o PORTAINER conseguirá identificar um dos servidores e será possível a configuração de ENDPOINTs

### PASSO 4: CONFIGURANDO JENKINS

#### DEPENDÊNCIA DO JENKINS

Instalar o plugin ``` Self-Organizing Swarm Plug-in Modules ```

#### CREDENCIAIS

Crie as credenciais para o Registry (usuário/senha) e para autenticação no bitbucket via SSH copiando a chave privada criada no passo ``` Configurando Chaves SSH ```
    
    http://<JENKINS_IP>/credentials/store/system/domain/_/newCredentials

#### CONFIGURANDO PIPELINE NO JENKINS

Use o projeto de exemplo contido no diretório APP

#### Jenkinsfile do projeto

Edite a variável ``` serverNames ``` com os mesmo nomes definidos no SERVERNAME no docker-compose do diretório ```swarm-client```

Edite o APP_NAME, BIND_PORT
Edite REGISTRY_REPO para o nome do registry onde serão armazenado os containers

#### Bitbucket configuration

Crie um repositório no bitbucket e copie a public key do Servidor de CI e adicione em Settings > Access Keys

e execute o comando para validar as chaves:
    
    ssh -T git@bitbucket.org

Configure o ``` multi branch pipeline ```

#### ADICIONANDO ENDPOINTs NO PORTAINER

Se foi configurado TLS, informar as chaves para o PORTAINER orquestrar os container nos servidores SLAVE.

Se a comunicação for via TCP informar o <HOST_IP>:<HOST_PORT> no campo ``` Endpoint URL ``` e salvar.

### REFERÊNCIAS

    https://github.com/krasi-georgiev/cd-demo/blob/master/Jenkinsfile
    
    https://medium.com/@maxy_ermayank/pipeline-as-a-code-using-jenkins-2-aa872c6ecdce

#### OBS: Falta implementar changelogs