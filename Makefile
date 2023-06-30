default: help

PROTOCOLS		= `ls protocols`

help:
	@echo "usage:"
	@echo "	make clean	remove generated files ignored by git"
	@echo "	make bug	apply bug patch files to protocol contract files"

bug:
	git apply $(CONTRACTS_DIR)/bugs/*.patch

clean:
	git checkout $(CONTRACTS_DIR)

test:
	for PROTOCOL in $(PROTOCOLS); do	\
		cd protocols/$$PROTOCOL;				\
		forge test;											\
		echidna . --contract EchidnaTester --config test/config.yaml;								\
		cd -;														\
	done

evaluate:
	echo TODO

mutate:
	echo TODO