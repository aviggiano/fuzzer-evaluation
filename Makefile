default: help

help:
	@echo "usage:"
	@echo "	make test			fuzz against default codebase"
	@echo "	make mutate			create patch files using mutation tools"
	@echo "	make evaluate <seed>		evaluate fuzzers after applying mutations for a particular seed"
	@echo "	make terraform			use terraform to deploy the infrastructure and start the evaluation"
	@echo "	make analyse <s3_bucket>	download results files from S3 for all launched instances and analyse the results"

test:
	./test.sh

mutate:
	./mutate.sh

evaluate:
	./evaluate.sh $(seed)

terraform:
	( cd terraform && terraform apply );

analyse:
	./analyse.sh $(s3_bucket)