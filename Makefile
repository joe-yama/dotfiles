.PHONY: apply diff doctor macos

apply:
	chezmoi apply -v

diff:
	chezmoi diff

doctor:
	chezmoi doctor

macos:
	@bash run_once_macos-defaults.sh
