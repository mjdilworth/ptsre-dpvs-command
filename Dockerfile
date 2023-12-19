# Build phase
FROM golang:1.20 AS builder
# Next line is just for debug
RUN ldd --version
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
WORKDIR /build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ptsre-adfo-app

# Production phase
FROM alpine:3.14
# Next line is just for debug
RUN ldd; exit 0
WORKDIR /app
COPY --from=builder /build/bin/ptsre-adfo-app .
ENTRYPOINT [ "/app/ptsre-adfo-app"]


# syntax=docker/dockerfile:1

FROM golang:1.17-alpine

# create a working directory inside the image
WORKDIR /app

# copy Go modules and dependencies to image
COPY go.mod ./

# download Go modules and dependencies
RUN go mod download

# copy directory files i.e all files ending with .go
COPY *.go ./

# compile application
RUN go build -o /ptsre-app

# tells Docker that the container listens on specified network ports at runtime
EXPOSE 8080

# command to be used to execute when the image is used to start a container
CMD [ "/ptsre-app" ]