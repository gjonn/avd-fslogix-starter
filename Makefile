# make plan ENV=prod   (falls back to ENV in .env, then dev)
-include .env
export

ENV ?= dev
VAR_FILE     := environments/$(ENV).tfvars
BACKEND_FILE := environments/$(ENV).backend.hcl
PLAN_FILE    := $(ENV).tfplan

.PHONY: init plan apply destroy rotate-token fmt validate lint check clean

init:
	terraform init -reconfigure -backend-config=$(BACKEND_FILE)

plan: init
	terraform plan -var-file=$(VAR_FILE) -out=$(PLAN_FILE)

apply:
	terraform apply $(PLAN_FILE)

destroy: init
	terraform destroy -var-file=$(VAR_FILE)

# reg token expires after 48h and the module never refreshes it.
# run this before adding hosts to an existing pool
rotate-token: init
	terraform plan -var-file=$(VAR_FILE) -out=$(PLAN_FILE) \
	  -replace='module.host_pool.azurerm_virtual_desktop_host_pool_registration_info.registrationinfo'

fmt:
	terraform fmt -recursive

validate:
	terraform init -backend=false -input=false >/dev/null
	terraform validate

lint:
	tflint --init && tflint

check: fmt validate lint

clean:
	rm -rf .terraform *.tfplan
