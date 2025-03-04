1, clone this git repository with 'git clone' to your local computer or to the server

2, install and start the Docker Desktop (it contains the Docker CLI)

3, in the .env file you can setup the initial variables (stay untouched for the test)

4, the docker-compose.yml file contains the initial setup, and it uses up the .env file for the variables. Start the environment with:
docker compose up

4, check the progress in the command line logs and in the docker desktop

5, you can add more containers with the start.sh script with the following parameters (in Windows):  ./start.sh liferayVersion imageName localhostPort:
./start.sh liferay/dxp:2024.q1.8 spider 38080
 
6, the script will start a new database (in the existing mysql container) with name spider and start the new container with corresponding Liferay version

7, you can check the progress in the docker desktop

8, check the the instance in the browser on localhost:38080

9, for stopping containers use the ./stop.sh containerName. It will remove the database with the same name and stop the container:
./stop.sh spider

Populate groovy scripts to the container:
- copy your groovy files to the /scripts folder. The folder is mounted to the containers /mnt/liferay/scripts folder

Load the Groovy script executor:
- copy the groovy script loader osgi module to the /groovy_script_runner folder. This folder is mounted to the containers /opt/liferay/deploy folder. It will start automatically.
