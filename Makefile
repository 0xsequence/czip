
all:
	@echo "Usage: make <target>"
	@echo "  where <target> is one of the following:"
	@echo "    foundryup"
	@echo "    foundrydown"
	@echo "    foundryclean"
	@echo "    foundryrestart"
	@echo "    foundrystatus"

bootstrap: check-forge check-huffc forge

check-forge: 
	@forge --version > /dev/null || { echo "forge cli not found. Please see README."; exit 1; }

check-huffc: 
	@huffc -v > /dev/null || { echo "huffc cli not found. Please see README."; exit 1; }

forge:
	forge install

build: build-czip-compressor

build-czip-compressor:
	@cd compressor; make build

test: build-czip-compressor
	@forge test "$@"
