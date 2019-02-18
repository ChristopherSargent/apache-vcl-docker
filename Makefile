# import environment file
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

MAKEFILEPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
VCLSOURCEDIR := $(shell dirname $(CURDIR))/vcl
.PHONY: build run clean

build:
	@echo Building containers
	@echo copying database initialization file from $(VCLSOURCEDIR)/mysql/vcl.sql to $(CURDIR)/mysql/data/vcl.sql
	@mkdir $(CURDIR)/mysql/data
	@cp -f $(VCLSOURCEDIR)/mysql/vcl.sql $(CURDIR)/mysql/data/vcl.sql
	docker-compose build
	@rm -r $(CURDIR)/mysql/data

run:
	@echo Running containers
	docker-compose up -d

clean:
	@echo Stopping containers
	@docker-compose stop
	@echo Removing stale containers
	@docker-compose rm -f
