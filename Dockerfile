# syntax=docker/dockerfile:1
##
## STEP 1 - BUILD
##


ARG build_version="darwin"
ARG app_name="ptsre-adfo-app"

ARG GOPROXY=https://artifacts-read.gkp.jpmchase.net/artifactory/go-external,direct
ARG GOOS=linux
ARG GOARCH=arm64
ARG http_proxy=http://proxy.jpmchase.net:8443
ARG https_proxy=http://proxy.jpmchase.net:8443
ARG no_proxy=localhost,.jpmchase.net,.jpmorganchase.com,.eks.amazonaws.com,127.0.0.1
ARG HTTP_PROXY=http://proxy.jpmchase.net:8443
ARG HTTPS_PROXY=http://proxy.jpmchase.net:8443

# specify the base image to  be used for the application, alpine or ubuntu

FROM jetae-publish.prod.aws.jpmchase.net/container-external/docker.io/arm64v8/alpine:3.14 AS build-stage
RUN apk add --no-cache git make musl-dev go

	

#FROM containerregistry-na.jpmchase.net/container-base/jpmcbase/lrh:8-arm64 AS build-stage
#FROM containerregistry-na.jpmchase.net/container-release/managedbaseimages/lrh:8-stable AS build
#RUN yum update -y
# install go
#RUN yum install golang -y


# create a working directory inside the image
WORKDIR /app

# copy Go modules and dependencies to image
COPY go.mod ./

# download Go modules and dependencies
RUN go mod download


# copy directory files i.e all files ending with .go
COPY . *.go ./

# compile application
RUN go build -o /ptsre-adfo-app

##
## STEP 2 - DEPLOY
##
FROM scratch

WORKDIR /

COPY --from=build-stage ptsre-adfo-app /ptsre-adfo-app

USER 1001

EXPOSE 8080

ENTRYPOINT ["/ptsre-adfo-app"]

# Add the artifact
#COPY bin/linux-amd64/${app_name} /home/jpmcnobody/${app_name}
#RUN chown jpmcnobody:jpmcnobody /home/jpmcnobody/${app_name} \
#&& chmod 755 /home/jpmcnobody/${app_name}