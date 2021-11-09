OS="$(uname -s)"
DOTBASE="$HOME/.dotfiles"
ZSH_DIR="${DOTBASE}/zsh"

HOST_NAME="$(hostname | cut -d"." -f1)"

set_hostname_title() {
    echo -ne "\033]0;"$(hostname | cut -d"." -f1)"\007"
}

################
#  ZSH config  #
################

precmd_functions+=(set_hostname_title)

set termguicolors

# cd without needing "cd"
setopt auto_cd

# Fix $ git reset --soft HEAD^ error.
unsetopt nomatch

# Append a trailing `/' to all directory names resulting from globbing
setopt mark_dirs

# Shift+Tab to get reverse menu completion
bindkey '^[[Z' reverse-menu-complete

export LANG=en_US.UTF-8
export EDITOR=nano
export VISUAL="$EDITOR"

#############
# Functions #
#############

# add ~/.my_zsh_functions to fpath, and then lazy autoload
# every file in there as a function
fpath=($DOTBASE/functions/autoload $fpath)
autoload -U cmd_exists

##########
# Prompt #
##########

if cmd_exists starship; then
    eval "$(starship init zsh)"
else
    sh <(curl -fsSL https://starship.rs/install.sh) -y >/dev/null
fi

#########
# zinit #
#########

. $ZSH_DIR/zinit

#################
#  ZSH Plugins  #
#################

z_plugins=(
    colored-man-pages
    safe-paste
    systemd
    common-aliases
    colorize
    git
    nvm
    yarn
)

for plugin in $z_plugins; do
    zinit wait lucid for OMZP::$plugin
done

###########
# History #
###########

setopt inc_append_history # append history list to the history file (important for multiple parallel>
setopt share_history      # import new commands from the history file also in other zsh-session
setopt extended_history   # save each command beginning timestamp and the duration to the history fi>
setopt hist_ignore_space  # remove command lines from the history list when the first character on t>

export HIST_STAMPS="mm/dd/yyyy"
export HISTSIZE=1000000000
export SAVEHIST=$HISTSIZE
export HISTFILE=~/.cache/zsh-histfile

# zsh-history-substring-search

setopt HIST_IGNORE_ALL_DUPS

###############
# Completions #
###############

zinit wait lucid for as'completion' OMZP::docker/_docker

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

zinit wait lucid light-mode for \
    silent atinit"ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    as"completion" \
    zsh-users/zsh-completions \
    atload"!export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=yellow,fg=white,bold'" \
    zsh-users/zsh-history-substring-search \
    pick"zsh-interactive-cd.plugin.zsh" \
    changyuheng/zsh-interactive-cd \
    pick"z.sh" \
    rupa/z \
    pick"git-it-on.plugin.zsh" \
    peterhurford/git-it-on.zsh #\

# Automatically refresh completions
zstyle ':completion:*' rehash true
# Highlight currently selected tab completion
zstyle ':completion:*' menu select
zstyle ':completion:*' completer _complete _expand _ignored _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*'
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# Use hyphen-insensitive completion. Case sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Include dotfiles in completions
setopt globdots

# homebrew completions
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

# pip zsh completion
_pip_completion() {
    local words cword
    read -Ac words
    read -cn cword
    reply=($(COMP_WORDS="$words[*]" \
        COMP_CWORD=$((cword - 1)) \
        PIP_AUTO_COMPLETE=1 $words[1]))
}
compctl -K _pip_completion pip

# type '...' to get '../..'
# Mikel Magnusson <mikachu@gmail.com> wrote this.
_rationalise-dot() {
    local MATCH MBEGIN MEND
    if [[ $LBUFFER =~ '(^|/| |    |'$'\n''|\||;|&)\.\.$' ]]; then
        LBUFFER+=/
        zle self-insert
    fi
    zle self-insert
}
zle -N _rationalise-dot
bindkey . _rationalise-dot
# without this, typing a . aborts incremental history search
bindkey -M isearch . self-insert

# Load completions
#fpath=(/usr/local/share/zsh-completions $fpath)
#autoload -U compinit && compinit -d $XDG_CACHE_HOME/zcompdump/default

#################
# Backgrounding #
#################

# Use Ctrl-z swap in and out of vim (or any other process)
# https://sheerun.net/2014/03/21/how-to-boost-your-vim-productivity/
ctrl-z-toggle() {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="setopt monitor && fg"
        zle accept-line
    else
        zle push-input
        zle clear-screen
    fi
}
zle -N ctrl-z-toggle
bindkey '^Z' ctrl-z-toggle

##########
#  Path  #
##########

. $ZSH_DIR/path

#############
#  Aliases  #
#############

. $ZSH_DIR/aliases

#######
# NVM #
#######

lazynvm() {
    unset -f nvm node npm npx
    export NVM_DIR=~/.nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
    if [ -f "$NVM_DIR/bash_completion" ]; then
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
    fi
}

nvm() {
    lazynvm
    nvm $@
}

node() {
    lazynvm
    node $@
}

npm() {
    lazynvm
    npm $@
}

npx() {
    lazynvm
    npx $@
}

########
# TMUX #
########

exit() {
    if [[ -z $TMUX ]]; then
        builtin exit
        return
    fi

    panes=$(tmux list-panes | wc -l)
    wins=$(tmux list-windows | wc -l)
    count=$(($panes + $wins - 1))
    if [ $count -eq 1 ]; then
        tmux detach
    else
        builtin exit
    fi
}

#########
# pyenv #
#########

if cmd_exists pyenv; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

if [ -f $DOTBASE/usertype.sh ]; then
    . $DOTBASE/usertype.sh
fi
