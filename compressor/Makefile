
build: build-pkgs build-cli

build-pkgs:
	go build ./...

build-cli:
	@GOBIN=$$PWD/bin $(MAKE) install

install:
	GOGC=off go install -v ./cmd/czip-compressor
