DEV_1PASSWORD_CREDENTIALS := $(shell cat ".secret/dev/1password-credentials.json" | base64)
DEV_1PASSWORD_CONNECT_TOKEN := $(shell cat ".secret/dev/.connect_token")
PROD_1PASSWORD_CREDENTIALS := $(shell cat ".secret/prod/1password-credentials.json" | base64)
PROD_1PASSWORD_CONNECT_TOKEN := $(shell cat ".secret/prod/.connect_token")

CONTAINER_EXEC ?= docker compose exec ansible-runner

bootstrap:
	: > .env && \
	echo "OP_DEV_SESSION=$(DEV_1PASSWORD_CREDENTIALS)" >> .env && \
	echo "OP_DEV_CONNECT_TOKEN=$(DEV_1PASSWORD_CONNECT_TOKEN)" >> .env && \
	echo "OP_PROD_SESSION=$(PROD_1PASSWORD_CREDENTIALS)" >> .env && \
	echo "OP_PROD_CONNECT_TOKEN=$(PROD_1PASSWORD_CONNECT_TOKEN)" >> .env && \
	docker compose --profile bootstrap up -d

clean:
	docker compose --profile clean down -v && \
	rm -fr ./cloud-init/.generated && \
	rm -fr ./.generated && \
	rm -fr .env

runner-setup:
	$(CONTAINER_EXEC) ansible-galaxy install -r requirements.yaml

gateway-setup:
	$(CONTAINER_EXEC) ansible-playbook -i inventory.yaml setup_gateway.yaml

external-setup:
	$(CONTAINER_EXEC) ansible-playbook -i inventory.yaml setup_external.yaml

node-setup:
	$(CONTAINER_EXEC) ansible-playbook -i inventory.yaml setup_node.yaml

backup-configuration:
	$(CONTAINER_EXEC) ansible-playbook -i inventory.yaml backup_configuration.yaml

