
all: test

test: format
	cabal test

build: format
	cabal build

format:
	./hindent-all

clean:
	cabal clean

setup:
	sudo apt-get install cabal-install
	cabal install hindent
	cabal install --run-tests

