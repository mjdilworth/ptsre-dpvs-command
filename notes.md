### some notes ###

take a look at this

https://gist.github.com/mbecker/f281c9f6f07b2b7beb5f6b6048cd14b8

to fix issues when API call to stop the logging goroutine as it hangs all other calls

- upon reflection i need to remove the ability to stop the go routine - 

kubectl run adfo --image=ptsre-adfo-app:v0.1.0 --image-pull-policy=Never --port=8080
kubectl port-forward pods/adfo 8080:8080


### at home on k3s

PVC use longhorn
https://longhorn.io/docs/1.5.3/deploy/install/install-with-kubectl/

basic auth ingress

USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth

sudo kubectl -n longhorn-system create secret generic basic-auth --from-file=auth


### privaet registry

the above longhorn didnt work too well - i removed it.

for private registry follow this:

https://k3s.rocks/private-registry/

# You should replace the username and password with more secure ones
export REGISTRY_USERNAME=mike
export REGISTRY_PASSWORD=mike
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: registry-basic-auth-secret
  namespace: default
data:
  users: |2
    $(htpasswd -Bbn $REGISTRY_USERNAME $REGISTRY_PASSWORD | base64)
EOF


priv-reg.yaml
piVersion: v1
kind: Secret
metadata:
  name: registry-basic-auth-secret
  namespace: default
data:
  users: |2
    $(htpasswd -Bbn mike mike | base64)
EOF

bWlrZTokMnkkMDUkMjRmTFFoajhrak5SczVTTkU1MElULmUyMjhwNnBGUGN3SXlwZThPdi5sb05Z
MEFNdnFKR2kKCg==

https://base64.co.za/create-docker-registry-with-letsencrypt/

/home/mjd/Projects/registry
cp privkey.pem domain.key
cat cert.pem chain.pem > domain.crt
chmod 777 domain.crt



docker run -d -p 5000:5000 --restart=always --name registry 

-v /home/mjd/Projects/registry/data:/var/lib/registry 


-v /home/mjd/Projects/registry/auth:/auth 
-e "REGISTRY_AUTH=htpasswd" 
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" 
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd 


-v /home/mjd/Projects/registry/certs:/certs 
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt 
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key 

registry:2

docker run -d -p 5000:5000 --restart=always --name registry -v /home/mjd/Projects/registry/data:/var/lib/registry -v /home/mjd/Projects/registry/auth:/auth -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v /home/mjd/Projects/registry/certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key registry:2


docker login lucinda.dilworth.uk:8080

mjd
0i

[Unit]
Description=ddclient

[Service]
ExecStart=/usr/sbin/ddclient -daemon 300 -syslog
WorkingDirectory=/tmp

[Install]
WantedBy=multi-user.target


https://mjd:xxxx@lucinda.dilworth.uk:8080/v2/_catalog
http://mjd:xxx@ella:8080/v2/_catalog


### deploy a containe ri can exec in to and run some tests

- build the docker image of debian from Dockerfile.deb
- docker build -f Dockerfile.deb --tag debian:v0.1.0 .

locally i have an image deb 
tag this for my registery lucinda.dilworth.uk:8080
docker tag deb lucinda.dilworth.uk:8080/deb
docker push lucinda.dilworth.uk:8080/deb

docker tag debian:v0.1.0 lucinda.dilworth.uk:8080/debian:v0.1.0
docker push lucinda.dilworth.uk:8080/debian:v0.1.0


### run docker desktop with
docker run -it --rm -p 5901:5901 -e USER=root debian-desktop     bash -c "touch /root/.Xresources && vncserver :1 -geometry 1280x800 -depth 24 && tail -F /root/.vnc/*.log"

### run docker image and keep it open
docker run -it debian /bin/bash

### deploy to k
kubectl create deployment my-deb --image=lucinda.dilworth.uk:8080/deb

exec on to is

kubectl exec --stdin --tty my-deb -- /bin/bash

### deploy a debian pos
kubectl run flow-pod -i --tty --image debian:unstable-slim -rm --restart=Never -- bash

kubectl run my-deb -i --tty --image debian:v0.1.0 --rm --restart=Never -- bash
kubectl run my-busy --image=busybox --rm -it --restart=Never -- sh

### exec on to pod

kubectl exec --stdin --tty debian -- /bin/bash

### liveness probe example
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5



      or try

      containers:
      - name: debian
        image: debian-desktop:v0.1.0
        ports:
        - containerPort: 5901
        livenessProbe:
          tcpSocket:
            port: 5901
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3

### useful on liveness and health probes
  https://apprecode.com/blog/kubernetes-rediness-liveness-probes#:~:text=What%20if%20we%20don't,of%20the%20PID%201%20process. 

