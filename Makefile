.PHONY: format

format:
	npx --yes markdownlint-cli --fix **/*.md
