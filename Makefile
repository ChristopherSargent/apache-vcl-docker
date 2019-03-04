# import environment file
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

MAKEFILEPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
VCLSOURCEDIR := $(shell dirname $(CURDIR))/vcl
.PHONY: build run clean ps

build:
	@echo Building db container
	@echo copying database initialization file from $(VCLSOURCEDIR)/mysql/vcl.sql to $(CURDIR)/mysql/data/vcl.sql
	@mkdir $(CURDIR)/mysql/data
	@cp -f $(VCLSOURCEDIR)/mysql/vcl.sql $(CURDIR)/mysql/data/vcl.sql
	@docker-compose build db
	@rm -r $(CURDIR)/mysql/data
	@echo Building web container
	@echo cleaning up stale files
	@sudo rm -rf $(VCLSOURCEDIR)/web/.ht-inc/conf.php $(VCLSOURCEDIR)/web/.ht-inc/cryptkey/cryptkeyid $(VCLSOURCEDIR)/web/.ht-inc/cryptkey/private.pem $(VCLSOURCEDIR)/web/.ht-inc/keys.pem $(VCLSOURCEDIR)/web/.ht-inc/pubkey.pem $(VCLSOURCEDIR)/web/.ht-inc/secrets.php
	@echo copying web source code files from $(VCLSOURCEDIR)/web to $(CURDIR)/web/src	
	@cp -rf $(VCLSOURCEDIR)/web $(CURDIR)/web/src
	@docker-compose build web
	@rm -rf $(CURDIR)/web/src
	@echo Building managementnode container
	@echo copying managementnode source code files from $(VCLSOURCEDIR)/managementnode to $(CURDIR)/managementnode/src
	@cp -rf $(VCLSOURCEDIR)/managementnode $(CURDIR)/managementnode/src
	@docker-compose build managementnode
	@rm -rf $(CURDIR)/managementnode/src

run:
	@echo Running containers
	docker-compose up -d

clean:
	@echo Stopping containers
	@docker-compose stop
	@echo Removing stale containers
	@docker-compose rm -f
	@echo Removing stale networks
	@docker network prune -f

ps:
	@echo showing status
	docker-compose ps
