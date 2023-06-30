default: help

help:
	@echo "usage:"
	@echo "	make test	fuzz against default codebase"
	@echo "	make mutate	apply bug patch files to protocol contracts"

test:
	./test.sh

mutate:
	./mutate.sh