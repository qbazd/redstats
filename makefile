.PHONY: all test examples

all: test

test:
	cutest -r ./test/helper.rb ./test/*test.rb

