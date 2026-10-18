ARCHES ?= arm64 amd64

.PHONY: all fetch check debs iso test-iso clean

all: iso

fetch:
	sh scripts/fetch.sh

check:
	sh desktop/trlde/tests/check.sh
	sh -n packages/vpx/vpx
	for f in packages/*/DEBIAN/p* iso/*.sh scripts/*.sh tests/*.sh; do sh -n "$$f" || exit 1; done
	python3 tools/pkglist.py include $(foreach a,$(ARCHES),--packages downloads/Packages-$(a).xz) >/dev/null
	@echo "Tüm OrvixOS kontrolleri başarılı."

debs: check
	sh scripts/build-debs.sh $(ARCHES)

iso: debs
	for a in $(ARCHES); do sh scripts/build-iso.sh $$a || exit 1; done

test-iso: debs
	mkdir -p build/test
	test -f build/test/id_ed25519 || ssh-keygen -q -t ed25519 -N '' -C orvixos-test -f build/test/id_ed25519
	for a in $(ARCHES); do ORVIXOS_TEST=1 ORVIXOS_TEST_BROWSER=vira sh scripts/build-iso.sh $$a || exit 1; done

clean:
	rm -rf build
