## Dockerfile for eth-net-intelligence-api (build from git).
##
## Build via:
#
# `docker build -t ethnetintel:latest .`
#
## Run via:
#
# `docker run -v <path to app.json>:/home/ethnetintel/eth-net-intelligence-api/app.json ethnetintel:latest`
#
## Make sure, to mount your configured 'app.json' into the container at
## '/home/ethnetintel/eth-net-intelligence-api/app.json', e.g.
## '-v /path/to/app.json:/home/ethnetintel/eth-net-intelligence-api/app.json'
## 
## Note: if you actually want to monitor a client, you'll need to make sure it can be reached from this container.
##       The best way in my opinion is to start this container with all client '-p' port settings and then 
#        share its network with the client. This way you can redeploy the client at will and just leave 'ethnetintel' running. E.g. with
##       the python client 'pyethapp':
##
#
# `docker run -d --name ethnetintel \
# -v /home/user/app.json:/home/ethnetintel/eth-net-intelligence-api/app.json \
# -p 0.0.0.0:30303:30303 \
# -p 0.0.0.0:30303:30303/udp \
# ethnetintel:latest`
#
# `docker run -d --name pyethapp \
# --net=container:ethnetintel \
# -v /path/to/data:/data \
# pyethapp:latest`
#
## If you now want to deploy a new client version, just redo the second step.


FROM debian

RUN apt-get update &&\
    apt-get install -y git &&\
	apt-get install -y curl &&\
    #curl -sL https://deb.nodesource.com/setup_11.x | bash - &&\
    apt-get update &&\
    apt-get install -y nodejs && \
	apt-get install -y npm 

RUN apt-get update &&\
    apt-get install -y build-essential

RUN adduser --disabled-password ethnetintel

RUN cd /home/ethnetintel &&\
    git clone https://github.com/cubedro/eth-net-intelligence-api &&\
    cd eth-net-intelligence-api &&\
    npm install &&\
    npm install -g pm2

RUN echo '#!/bin/bash\nset -e\n\ncd /home/ethnetintel/eth-net-intelligence-api\npm2 start ./app.json\n sleep 5 \n\ntail \
    /home/ethnetintel/.pm2/logs/node-app-out-0.log \n\n export WS_SECRET=mysecret && npm start --prefix /home/eth-netstats' > /home/ethnetintel/startscript.sh

	
COPY app.json /home/ethnetintel/eth-net-intelligence-api/app.json


RUN cd /home &&\ 
    git clone https://github.com/cubedro/eth-netstats.git &&\
   cd eth-netstats &&\
   npm install && \
   npm install -g grunt &&\
   grunt all
   

RUN chmod +x /home/ethnetintel/startscript.sh &&\
    chown -R ethnetintel. /home/ethnetintel &&\
	 chown -R ethnetintel. /home/eth-netstats 
   

USER ethnetintel
ENTRYPOINT ["/home/ethnetintel/startscript.sh"]
