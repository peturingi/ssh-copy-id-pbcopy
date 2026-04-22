MAKEFILE_ROOT := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
SCRIPT        := ssh-copy-id
SCRIPT_PATH   := $(MAKEFILE_ROOT)/$(SCRIPT)-pbcopy
MARKER        := github.com/peturingi/ssh-copy-id-pbcopy

.PHONY: install remove uninstall
uninstall: remove
install:
	@set -eu; \
	test -f "$(SCRIPT_PATH)" || { echo "ERROR: $(SCRIPT_PATH) not found" >&2; exit 1; }; \
	shell=$$(basename "$${SHELL:-sh}"); \
	case "$$shell" in \
		zsh)  rc="$$HOME/.zshrc" ;; \
		bash) if [ -f "$$HOME/.bash_profile" ]; then rc="$$HOME/.bash_profile"; \
			  else rc="$$HOME/.profile"; fi ;; \
		*)    rc="$$HOME/.profile" ;; \
	esac; \
	sci=$$(command -v ssh-copy-id 2>/dev/null || true); \
	if [ -z "$$sci" ]; then \
		echo "ERROR: ssh-copy-id not found on PATH. Install openssh-client first." >&2; \
		exit 1; \
	fi; \
	if grep -Fq "$(MARKER)" "$$sci" 2>/dev/null; then \
		dest=$$(dirname "$$sci"); \
		case ":$$PATH:" in *":$$dest:"*) on_path=1 ;; *) on_path=0 ;; esac; \
		in_rc=0; \
		[ -f "$$rc" ] && grep -Fq "PATH=\"$$dest:" "$$rc" && in_rc=1; \
		if [ "$$on_path" = 1 ] || [ "$$in_rc" = 1 ]; then \
			echo "Already installed at $$sci; $$dest is already reachable." >&2; \
			echo "Nothing to do." >&2; \
			exit 2; \
		fi; \
		echo "Wrapper already installed at $$sci; only PATH needs updating."; \
	else \
		case "$$sci" in \
			/usr/bin/ssh-copy-id|/bin/ssh-copy-id|/usr/local/bin/ssh-copy-id|/opt/homebrew/bin/ssh-copy-id) ;; \
			*) \
				echo "WARNING: Found ssh-copy-id at non-standard location: $$sci" >&2; \
				printf 'Continue anyway? [y/N]: '; \
				read ans; \
				case "$$ans" in y|Y|yes|YES) ;; *) echo "Aborting."; exit 1 ;; esac ;; \
		esac; \
		printf 'Install %s where? [%s/.local/bin/]: ' "$(SCRIPT)" "$$HOME"; \
		read dest; \
		: "$${dest:=$$HOME/.local/bin/}"; \
		dest=$$(eval echo "$$dest"); \
		if [ ! -d "$$dest" ]; then \
			parent=$$dest; \
			while [ ! -d "$$parent" ]; do parent=$$(dirname "$$parent"); done; \
			if [ ! -w "$$parent" ]; then \
				echo "ERROR: $$dest does not exist and $$parent is not writable." >&2; \
				exit 1; \
			fi; \
			printf 'No such directory: %s. Create it? [Y/n]: ' "$$dest"; \
			read ans; \
			case "$$ans" in \
				n|N|no|NO) echo "Aborting."; exit 1 ;; \
			esac; \
			mkdir -p "$$dest"; \
		fi; \
		install -m 0755 "$(SCRIPT_PATH)" "$$dest/$(SCRIPT)"; \
		echo "Installed $$dest/$(SCRIPT)"; \
	fi; \
	case ":$$PATH:" in \
		*":$$dest:"*) exit 0 ;; \
	esac; \
	if [ -f "$$rc" ] && grep -Fq "PATH=\"$$dest:" "$$rc"; then \
		echo "$$rc already exports $$dest. Open a new shell or: source $$rc" >&2; \
		exit 2; \
	fi; \
	printf '%s is not on PATH. Append to %s? [Y/n]: ' "$$dest" "$$rc"; \
	read ans; \
	case "$$ans" in \
		n|N|no|NO) echo "Skipped. Add manually: export PATH=\"$$dest:\$$PATH\"" >&2; exit 2 ;; \
	esac; \
	touch "$$rc"; \
	printf '\n# added by %s installer — https://github.com/peturingi/ssh-copy-id-pbcopy\nexport PATH="%s:$$PATH"\n\n' "$(SCRIPT)" "$$dest" >> "$$rc"; \
	echo "Appended to $$rc."; \
	echo; \
	echo "NOTE: already-open shells won't see the change until each of them runs"; \
	echo "      'source $$rc' (or is closed and reopened). In those shells,"; \
	echo "      'ssh-copy-id' still resolves to the system binary and will NOT"; \
	echo "      install pbcopy on the remote."

remove:
	@set -eu; \
	found=0; \
	candidates=$$( \
		{ command -v -a ssh-copy-id 2>/dev/null || true; \
		  printf '%s\n' "$$HOME/bin/ssh-copy-id" "$$HOME/.local/bin/ssh-copy-id" \
		                "/usr/local/bin/ssh-copy-id" "/opt/homebrew/bin/ssh-copy-id"; \
		} | awk '!seen[$$0]++'); \
	for p in $$candidates; do \
		[ -f "$$p" ] || continue; \
		grep -Fq "$(MARKER)" "$$p" 2>/dev/null || continue; \
		printf 'Remove %s? [Y/n]: ' "$$p"; \
		read ans; \
		case "$$ans" in n|N|no|NO) continue ;; esac; \
		rm -f -- "$$p" && echo "Removed $$p"; \
		found=1; \
	done; \
	for rc in "$$HOME/.zshrc" "$$HOME/.bash_profile" "$$HOME/.profile"; do \
		[ -f "$$rc" ] || continue; \
		grep -Fq "$(MARKER)" "$$rc" || continue; \
		printf 'Strip installer block from %s? [Y/n]: ' "$$rc"; \
		read ans; \
		case "$$ans" in n|N|no|NO) continue ;; esac; \
		tmp=$$(mktemp); \
		awk -v m="$(MARKER)" '\
			/^# added by .* installer/ && index($$0,m) { skip=1; next } \
			skip && /^export PATH=/        { skip=0; next } \
			skip && /^[[:space:]]*$$/      { skip=0; next } \
			{ print }' "$$rc" > "$$tmp" && mv -- "$$tmp" "$$rc"; \
		echo "Cleaned $$rc"; \
		found=1; \
	done; \
	if [ "$$found" = 0 ]; then \
		echo "Nothing installed by this tool was found." >&2; \
		exit 2; \
	fi
