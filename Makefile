CONFIG_PATH ?= bitbucketdc.jpmchase.net/<fabric-project>/<fabric-repo>/internal/constants
BINARY_NAME ?= ptsre-adfo-app
VERSION ?= 0.0.1
BUILD_DIR := bin
GIT_REV_PARSE := $(shell git rev-parse HEAD)
COMMIT_ID := $(if ${GIT_REV_PARSE},${GIT_REV_PARSE},unknown)
DATECMD := date$(if $(findstring Windows,$(OS)),.exe,)
BUILD_TIMESTAMP := $(shell ${DATECMD} +%Y-%m-%dT%H:%m:%S%z)
.DEFAULT_GOAL := all

ARCHES = amd64 arm64 ppc64le s390x

# BUILDARCH is the host architecture
# ARCH is the target architecture
# we need to keep track of them separately
BUILDARCH ?= $(shell uname -m)

# canonicalized names for host architecture
ifeq ($(BUILDARCH),aarch64)
	BUILDARCH=arm64
endif
ifeq ($(BUILDARCH),x86_64)
	BUILDARCH=amd64
endif

# unless otherwise set, I am building for my own architecture, i.e. not cross-compiling
ARCH ?= $(BUILDARCH)

# canonicalized names for target architecture
ifeq ($(ARCH),aarch64)
	override ARCH=arm64
endif
ifeq ($(ARCH),x86_64)
	override ARCH=amd64
endif

os_arch = $(word 4, $(shell go version))
os = $(word 1,$(subst /, ,$(os_arch)))
arch = $(word 2,$(subst /, ,$(os_arch)))


DOCKER_REGISTRY := #if set it should finished by /
EXPORT_RESULT := false # for CI please set EXPORT_RESULT to true

GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)


.PHONEY: hello
## hello:
hello: ## dummy help build for the makefile
	echo "hello"
	echo "always print hello does not exist"

.PHONEY: me
## me:
me: ## build for local architrcrture
	@make --no-print-directory build-platform GOOS=${os} GOARCH=${arch}  CGO_ENABLED=0
	

.PHONEY: build
## build:
build: ## build your project 
	@make --no-print-directory build-platform GOOS=windows GOARCH=amd64 CGO_ENABLED=0
	@make --no-print-directory build-platform GOOS=linux GOARCH=amd64 CGO_ENABLED=0
	@make --no-print-directory build-platform GOOS=darwin GOARCH=amd64 CGO_ENABLED=0
	@make --no-print-directory build-platform GOOS=${os} GOARCH=${arch}  CGO_ENABLED=0
	

.PHONY: win
## win:
 win: ## build for windows
	@make --no-print-directory build-platform GOOS=windows GOARCH=amd64 KERBEROS_DEFAULT=true

.PHONY: build-platform
## build-platform:
build-platform: ## build project to platform as use dby jules
	@echo Building ${GOOS}-${GOARCH}
	$(eval BINARY := ${BINARY_NAME}$(if $(findstring windows,$(GOOS)),.exe,))
	go build -v -o ${BUILD_DIR}/${GOOS}-${GOARCH}/$(BINARY) \
		-ldflags=all="-X ${CONFIG_PATH}.Version=${VERSION} -X ${CONFIG_PATH}.CommitId=${COMMIT_ID} -X ${CONFIG_PATH}.BuildTimestamp=${BUILD_TIMESTAMP}" .


.PHONY: build_pi
## build_pi:
build_pi: ## build your project for an old pi - arch arm
	GOARCH=arm		GOARM=5	GOOS=linux go build -o ${BINARY_NAME}-pi ./${BUILD_DIR}/.

.PHONY: clean
## clean:
clean: ## clean the project	add "-" before command so if error it is ignored
	go	clean
	rm -rf ${BUILD_DIR}

.PHONY: fmt
## fmt:
fmt: ## format nicely
	go fmt ./...

.PHONY: tidy
## tidy:
tidy: ## mod tidy
	go mod tidy -v

.PHONY: test
## test:
test: ## run tests
ifeq (${MAKECMDGOALS},ci)
	go test -v -coverpkg=./... -coverprofile=coverage.out -json ./... -count=1 > test-report.json || (cat test-report.json; exit 1)
else
	go test -v -coverpkg=./... -coverprofile=coverage.out ./... -count=1
endif

.PHONY: cover
## cover:
cover: test ## run test coverage
	go tool cover -html=coverage.out


.PHONY: ci
## ci:
ci: clean test build ## as used by jules, cleans, tests an dbuilds


## Docker:
docker-build: ## Use the dockerfile to build the container
	docker build --rm --tag $(BINARY_NAME) .

docker-release: ## Release the container with tag latest and version
	docker tag $(BINARY_NAME) $(DOCKER_REGISTRY)$(BINARY_NAME):latest
	docker tag $(BINARY_NAME) $(DOCKER_REGISTRY)$(BINARY_NAME):$(VERSION)
	# Push the docker images
	docker push $(DOCKER_REGISTRY)$(BINARY_NAME):latest
	docker push $(DOCKER_REGISTRY)$(BINARY_NAME):$(VERSION)


## Help:
help: ## Show this help.
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)