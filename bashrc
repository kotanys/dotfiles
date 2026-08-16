# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

if [[ "$(cat /etc/hostname 2>/dev/null)" == toolbx ]] || [[ "$DISTROBOX_ENTER_PATH" ]]; then
    return
fi

export LC_ALL=en_US.UTF-8

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
export HISTCONTROL=ignoreboth
export HISTSIZE=5000

shopt -s checkwinsize nullglob globstar histappend

PS1HOSTNAME='@\h'
if [[ ! -r /etc/hostname ]] || [[ "$(cat /etc/hostname)" == kotanyspc ]]; then
    PS1HOSTNAME=''
fi
PS1='\[\033[01;32m\]\u'"$PS1HOSTNAME"':\[\033[01;34m\]\w\[\033[00m\]\$ '
unset PS1HOSTNAME

IGNOREEOF=1

# make less show colors (see less(1))
export LESS='-R'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    fi
fi

# tldr config
# NOTE to future self - this shit doubles bash startup time (noticeable)
# eval "$(tldr --print-completion bash)"

# zoxide config
eval "$(zoxide init bash)"

# fzf config
FZF_ALT_C_COMMAND='' eval "$(fzf --bash)"

# PATHing
export GOPATH="$HOME/.local/share/go"
if [[ -d "$GOPATH/bin" ]] && [[ ! "$PATH" =~ $GOPATH/bin ]]; then
    PATH="$PATH:$GOPATH/bin"
fi
if [[ -d "$HOME/.dotnet/tools" ]] && [[ ! "$PATH" =~ $HOME/.dotnet/tools ]]; then
    export POWERSHELL_TELEMETRY_OPTOUT=1
    PATH="$PATH:$HOME/.dotnet/tools"
fi
if [[ -x ~/opt/install.bash ]]; then
    PATH="$(~/opt/install.bash --path)$PATH"
fi

export PATH
export EDITOR="$(which nvim)"

# fortune+cowsay meme
if [[ ! -f ~/.local/state/cowsay-meme-disable ]] &&
    [[ "$SHLVL" = 1 ]] &&
    command -v fortune &>/dev/null &&
    command -v cowsay &>/dev/null; then
    fortune -sa | cowsay
fi

cowsay-enable-meme() {
    if [[ -s ~/.local/state/cowsay-meme-disable ]]; then
        echo "$HOME/.local/state/cowsay-meme-disable is not an empty file!" >&2
        return 1
    fi
    rm -f ~/.local/state/cowsay-meme-disable
}
cowsay-disable-meme() {
    touch ~/.local/state/cowsay-meme-disable
}

feline() {
    # A char-by-char `cat`. Useful for apps with no buffering.
    # Doesn't work with null bytes!
    if (($# == 0)); then
        set -- -
    fi
    while (($# != 0)); do
        local file=$1
        [[ $1 == - ]] && file=/dev/stdin

        while IFS= read -r -N1 char; do
            printf "%s" "$char"
        done <"$file"
        shift
    done
}

cas() {
    # ls or cat, depending on file type
    # Note: flags are passed to ls but not to cat
    local file="$1"
    shift
    local arguments=("$@")
    if [[ ! -e $file ]]; then
        echo "${FUNCNAME[0]}: can't stat '$file'"
        return 1
    fi
    case "$(LC_ALL=C stat -Lc %A -- "$file")" in
    d*) ls "${arguments[@]}" -- "$file" ;;
    -*) cat -- "$file" ;;
    *) echo "${FUNCNAME[0]}: neither a file nor a directory" ;;
    esac
}

# ~/.bashrc.local should be ignored by version control
if [[ -f ~/.bashrc.local ]]; then
    source ~/.bashrc.local
fi

### ALIASES

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias tree='tree -C'

# for consistency with Vim's :mak[e]
if command -v make &>/dev/null; then
    alias mak='make'
fi
alias :q='exit'

alias mv='mv -v'
alias cp='cp -v'
alias ll='ls -alhF'

if command -v nvim &>/dev/null; then
    alias vim='nvim'
fi

# git aliases
alias gad='git add'
alias gst='git status'
alias glg='git log'
alias gla='git log --graph --all'
alias gph='git push'
alias gphu='git push -u $(git remote | head -n1) $(git branch --show-current)'
alias gch='git checkout'
alias amend='git commit --amend'

# prevent commands like gcm --amend
gcm() {
    if [[ $1 =~ ^-.* ]]; then
        echo "gcm is 'git commit -m'." >&2
        echo "If you really want your commit message to be $1, don't use this alias" >&2
        return 127
    fi
    git commit -m "$@"
}

# setup completion for git aliases
source /usr/share/bash-completion/completions/git
__git_complete gad git_add
__git_complete gcm git_commit
__git_complete gst git_status
__git_complete glg git_log
__git_complete gla git_log
__git_complete gph git_push
__git_complete gch git_checkout
__git_complete amend git_commit
