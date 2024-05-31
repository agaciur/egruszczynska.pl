SHELL := /bin/bash
.SHELLFLAGS += -e
.PHONY: purge can-i-deploy git-revision pack deploy deploy-prod


purge:
	rm -f pack.tar .revision


can-i-deploy:
	if [[ "$(SSH_HOST)" == "" ]]; then echo "Missing SSH_HOST parameter"; exit 1; fi
	if [[ "$(DOMAIN)" == "" ]]; then echo "Missing URL parameter"; exit 1; fi
	if [[ `ssh $(SSH_HOST) "cat ~/domains/$(DOMAIN)/public_html/current/.revision"` == `cat .revision` ]]; then \
		echo "Cannot deploy the same repository revision"; \
		exit 1; \
	fi


git-revision:
	echo `git describe --tags --always` > .revision


pack:
	rm -Rf pack.tar
	tar \
		--exclude='*DS_Store' --exclude='pack.tar' --exclude='.git' \
		--exclude='.gitignore' --exclude='README.md' --exclude='.idea' \
		--exclude='Makefile' --exclude='CNAME' --exclude='tmp' \
		-cf pack.tar .


deploy: git-revision
	make can-i-deploy DOMAIN=$(DOMAIN)
	make pack

	if [[ "$(DOMAIN)" == "" ]]; then echo "Missing DOMAIN parameter"; exit 1; fi
	if [[ "$(SSH_HOST)" == "" ]]; then echo "Missing SSH_HOST parameter"; exit 1; fi

	ssh $(SSH_HOST) "cd ~/domains/$(DOMAIN)/public_html/ " \
		'&& for version in ./v[0-9]*.[0-9]*; do if [ "$$version" != "./$$(readlink ./current | cut -d "/" -f 1)" ]; then rm -Rf "$$version"; fi; done' \
		"&& unlink current" \
		"; rm -Rf `cat .revision`" \
		"&& mkdir `cat .revision`"

	scp pack.tar $(SSH_HOST):"~/domains/$(DOMAIN)/public_html/`cat .revision`" && make purge

	ssh $(SSH_HOST) "cd ~/domains/$(DOMAIN)/public_html/"`cat .revision`" " \
		"&& tar xf pack.tar " \
		"&& rm -f pack.tar " \
		"&& cd .. && ln -sf "`cat .revision`" current "


deploy-prod:
	make deploy DOMAIN='egruszczynska.pl' SSH_HOST='h5'
