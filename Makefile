CREDENTIALS := $(shell cat ".secret/1password-credentials.json" | base64)
CONNECT_TOKEN := $(shell cat ".secret/.connect_token")

CONTAINER_EXEC ?= docker compose exec ansible-runner

clean-all:
	docker compose --profile clean down -v && \
	rm -fr ./cloud-init/.generated && \
	rm -fr ./.generated && \
	rm -fr .env

pre-setup:
	touch .env && \
	echo "OP_PROD_SESSION=$(CREDENTIALS)" >> .env && \
	echo "OP_PROD_CONNECT_TOKEN=$(CONNECT_TOKEN)" >> .env && \
	docker compose --profile pre-setup build  && \
	docker compose --profile pre-setup up -d

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

