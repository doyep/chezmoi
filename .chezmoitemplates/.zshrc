# Load common config
source ~/.shell_common

# homebrew
if command -v brew >/dev/null; then
  eval "$(brew shellenv)"
fi

# zoxide
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# fzf
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

# Initialize zsh completion system (enables tab completion for commands, options, etc.)
autoload -Uz compinit && compinit

# yazi - shorthand
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# fnm - env
eval "$(fnm env --use-on-cd --shell zsh)"

# Load Angular CLI autocompletion.
source <(ng completion script)
