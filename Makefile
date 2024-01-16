script_dir := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

fmt:
	@cd $(script_dir) && \
	terraform fmt -recursive

generate:
	@cd $(script_dir) && \
	bash ./modules/apps/builder/generate_app_variables.sh

validate:
	@cd $(script_dir) && \
	terraform validate

test.integration: generate validate fmt
	@cd $(script_dir) && \
	bash ./integration/test.sh

test.reset: generate validate fmt
	@cd $(script_dir) && \
	bash ./integration/reset.sh

test.verify: generate validate fmt
	@cd $(script_dir) && \
	bash ./integration/verify.sh

terraform.apply: generate validate fmt
	@cd $(script_dir) && \
	cd ./integration && \
	terraform apply && \
	bash ./verify.sh

terraform.destroy: generate validate fmt
	@cd $(script_dir) && \
	cd ./integration && \
	terraform destroy
