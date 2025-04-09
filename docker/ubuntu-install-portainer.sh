-------------------------------------
# install a new portainer

docker volume create portainer_data

docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

-------------------------------------
# update a live portainer

# download the latest portainer image
docker image pull portainer/portainer-ce:latest

# stop the portainer container
docker container stop portainer_name

# remove the portainer container
docker container rm portainer_name

# create the portainer container
docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
