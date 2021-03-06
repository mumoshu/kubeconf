# find or download addlicense
addlicense:
ifeq (, $(shell which addlicense))
	@{ \
	set -e ;\
	INSTALL_TMP_DIR=$$(mktemp -d) ;\
	cd $$INSTALL_TMP_DIR ;\
	go mod init tmp ;\
	go get github.com/google/addlicense ;\
	rm -rf $$INSTALL_TMP_DIR ;\
	}
ADDLICENSE=$(GOBIN)/addlicense
else
ADDLICENSE=$(shell which addlicense)
endif

# find or download goreleaser
goreleaser:
ifeq (, $(shell which goreleaser))
	@{ \
	set -e ;\
	INSTALL_TMP_DIR=$$(mktemp -d) ;\
	cd $$INSTALL_TMP_DIR ;\
	go mod init tmp ;\
	go get github.com/goreleaser/goreleaser ;\
	rm -rf $$INSTALL_TMP_DIR ;\
	}
GORELEASER=$(GOBIN)/goreleaser
else
GORELEASER=$(shell which goreleaser)
endif

.PHONY: format
format:
	gofmt -w .

.PHONY: test/format
test/format:
	gofmt -s -d . > gofmt.out
	test -z "$$(cat gofmt.out)" || (cat gofmt.out && rm gofmt.out && false)

.PHONY: test/release
test/release: goreleaser
	$(GORELEASER) release --snapshot --skip-publish --rm-dist

VERSION ?= v0.2.1

.PHONY: test/krew-template
test/krew-template:
	docker run -v $(PWD)/.krew-release-bot.yaml:/tmp/template-file.yaml rajatjindal/krew-release-bot:v0.0.38 \
	krew-release-bot template --tag $(VERSION) --template-file /tmp/template-file.yaml > .krew.yaml

.PHONY: test/krew-install
test/krew-install:
	kubectl krew uninstall config-registry || true
	kubectl krew install --manifest=.krew.yaml
	kubectl krew uninstall config-registry

.PHON: test/krew
test/krew: test/krew-template test/krew-install

.PHONY: test/go
test/go:
	go test ./...

.PHONY: check
check: test/format test/release test/krew-template test/go

.PHONY: build
build:
	go build ./cmd/config-registry
