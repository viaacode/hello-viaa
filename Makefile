# Convenience scripts to install githooks
git:
	git config core.hooksPath .githooks;
	chmod +x .githooks/*
	git flow init;

