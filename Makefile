default: help

help:
	@echo "usage:"
	@echo "	make test		fuzz against default codebase"
	@echo "	make mutate		create patch files using mutation tools"
	@echo "	make evaluate <seed>	evaluate different fuzzers after applying mutations"
	@echo "	make terraform		use terraform to deploy the infrastructure and start the evaluation"

test:
	./test.sh

mutate:
	./mutate.sh

evaluate:
	./evaluate.sh $(seed)

terraform:
	( cd infrastructure && terraform apply );