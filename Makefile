.PHONY: install uninstall test sync-omarchy install-fips uninstall-fips test-fips

install:
	@bash scripts/install.sh

uninstall:
	@bash scripts/uninstall.sh

# Syntax-check shell files and dry-run stow
test:
	@bash -n home/.bashrc home/.local/share/omarchy-shell/portable scripts/*.sh
	@stow -n --no-folding --dir=. --target="$(HOME)" home && echo "ok"

# On an Omarchy machine: refresh the bundled copy of Omarchy's bash defaults
sync-omarchy:
	@rsync -a --delete /usr/share/omarchy/default/bash/ home/.local/share/omarchy-shell/default/bash/
	@git status --short home/.local/share/omarchy-shell

# FIPS 140-3 path (Oracle Linux 9.x only, see docs/FIPS.md)
install-fips:
	@bash scripts/install-fips.sh

uninstall-fips:
	@stow -D --dir="$(CURDIR)" --target="$(HOME)" home-fips

test-fips:
	@bash scripts/test-fips.sh
