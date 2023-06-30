default: help

help:
	@echo "usage:"
	@echo "	make test	fuzz against default codebase"
	@echo "	make mutate	create patch files using mutation tools"
	@echo "	make evaluate	evaluate different fuzzers after applying mutations"

test:
	./test.sh

mutate:
	./mutate.sh

evaluate:
	./evaluate.sh

screen:
	screen -L -d -m make evaluate