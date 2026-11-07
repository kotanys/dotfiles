# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

if [[ "$(cat /etc/hostname 2>/dev/null)" == toolbx ]] || [[ "$DISTROBOX_ENTER_PATH" ]]; then
    return
fi

export LC_ALL=en_US.UTF-8
if command -v nvim &>/dev/null; then
    export EDITOR=nvim
elif command -v vim &>/dev/null; then
    export EDITOR=vim
fi

export VISUAL=$EDITOR

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
HISTSIZE=5000
IGNOREEOF=1

shopt -s checkwinsize nullglob globstar histappend

if [[ -r /etc/hostname ]] && [[ "$(cat /etc/hostname)" != kotanyspc ]]; then
    ps1hostname='@\h'
fi
ps1errorcode='$(c=$?;((c))&&printf "\e[31;m%s\e[0;m " $c)'

PS1="$ps1errorcode"'\[\033[01;32m\]\u'"${ps1hostname-}"':\[\033[01;34m\]\w\[\033[00m\]\$ '
unset ps1hostname ps1errorcode

# # Funny clock
# while
#     sleep 1 &&
#     printf '\e7\e[2;%dH\e[1m%s\e[0m\e8' $((COLUMNS - 12)) "${ date +"  %H:%M:%S  "; }"
# do
#     :
# done &


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

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

if command -v fzf &>/dev/null; then
    FZF_ALT_C_COMMAND='' eval "$(fzf --bash)"
fi

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

if command -v make &>/dev/null; then
    alias mak='make'
fi
alias :q='exit'

alias mv='mv -v'
alias cp='cp -v'
alias rm='rm -v'
alias ll='ls -alhF'

if command -v nvim &>/dev/null; then
    alias vim='nvim'
fi

# git aliases
alias gad='git add'
alias gst='git status'
alias glg='git log --pretty=oneline --abbrev-commit'
alias gla='git log --graph --all'
alias gph='git push'
alias gphu='git push -u $(git remote | head -n1) $(git branch --show-current)'
alias gch='git checkout'
alias amend='git commit --amend'

alias nolid='systemd-inhibit --what=handle-lid-switch sleep infinity'

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
if [[ -r /usr/share/bash-completion/completions/git ]]; then
    source /usr/share/bash-completion/completions/git
    __git_complete gad git_add
    __git_complete gcm git_commit
    __git_complete gst git_status
    __git_complete glg git_log
    __git_complete gla git_log
    __git_complete gph git_push
    __git_complete gch git_checkout
    __git_complete amend git_commit
fi
