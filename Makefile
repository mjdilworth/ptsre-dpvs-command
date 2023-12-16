
BINARY_NAME := ptsre-app
DOCKER_REGISTRY := #if set it should finished by /
EXPORT_RESULT := false # for CI please set EXPORT_RESULT to true

GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

.PHONEY: all test build build_all build_pi run hello

hello:
	echo "hello"
	echo "always print hello does not exist"

## build:
build: ## build your project 
	go	build	-o	${BINARY_NAME}	./bin/.

## build_pi:
build_pi: ## build your project for mike's old pi
	GOARCH=arm		GOARM=5	GOOS=linux go build -o ${BINARY_NAME}-pi ./cmd/.

## build_all:
build_all: ## build your project 
	go	build	-o	${BINARY_NAME}	./cmd/.
	GOARCH=amd64	GOOS=darwin	go	build	-o	${BINARY_NAME}-darwin	./cmd/.
	GOARCH=amd64	GOOS=linux	go	build	-o	${BINARY_NAME}-linux	./cmd/.
	GOARCH=amd64	GOOS=windows	go	build	-o	${BINARY_NAME}-windows	./cmd/.
	$(MAKE) build_pi
	
## run:
run: build ## run the project
	./bin/${BINARY_NAME}

## build_and_run:
build_and_run: ## build and run
	build run

## clean:
clean: ## clean the project	add "-" before command so if error it is ignored
	go	clean
	-rm	.bin/${BINARY_NAME}
	-rm	.bin/${BINARY_NAME}-darwin
	-rm	.bin/${BINARY_NAME}-linux	
	-rm	.bin/${BINARY_NAME}-windows
	-rm	.bin/${BINARY_NAME}-pi


## test:
test: ## run tests
	go test -v ./... -count=1
ifeq ($(EXPORT_RESULT),true)
	## GO111MODULE=off go get -u github.com/jstemmer/go-junit-report
	## $(eval OUTPUT_OPTIONS = | tee /dev/tty | go-junit-report -set-exit-code > junit-report.xml)		echo "no report"
endif
	go test -v -race ./... $(OUTPUT_OPTIONS)

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