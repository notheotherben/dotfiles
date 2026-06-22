# fish shell config — deployed by chezmoi to ~/.config/fish/config.fish
# Replaces the old nix programs.fish shellInit / interactiveShellInit blocks.
# PATH additions and env vars (VAULT_ADDR, GITTOOL_CONFIG, ~/.cargo/bin, …)
# come from mise — see ~/.config/mise/config.toml.

# Tool versions, PATH and env vars
if type -q mise
    mise activate fish | source
end

# Prompt
if type -q starship
    starship init fish | source
end

# Shell history sync
if type -q atuin
    atuin init fish | source
end

# git-tool integration + completions
if type -q git-tool
    git-tool shell-init fish | source
    complete -f -c git-tool -a "(git-tool complete (commandline -cp))"
end

# 1Password CLI completion (op is installed manually — latest beta)
if type -q op
    op completion fish | source
end

if -f ~/export-esp.sh
    source ~/export-esp.sh
end

# Aliases (was nix environment.shellAliases / home.shellAliases)
alias gt 'git-tool'
alias http 'xh'
