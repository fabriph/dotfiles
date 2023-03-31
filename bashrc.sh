#!/bin/bash

# git mail and user
# Fab <fabriph@users.noreply.github.com>
# git filter-branch -f --env-filter "GIT_AUTHOR_NAME='Fab'; GIT_AUTHOR_EMAIL='fabriph@users.noreply.github.com'; GIT_COMMITTER_NAME='Fab'; GIT_COMMITTER_EMAIL='fabriph@users.noreply.github.com';" HEAD
# git push --force --tags origin master



# TO DO list:
# - Improve TAB compeltion:
#   - http://stackoverflow.com/questions/10942919/customize-tab-completion-in-shell
#   - http://superuser.com/questions/289539/custom-bash-tab-completion
#   - Maybe taking a look at ~/.git-completion.bash helps
# - Compress paths of PS1 if it's too long or too many directories.
# - Format cmd runtime in hours/min/sec... instead of just seconds.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


bashrc_start=`date +%s.%N`
fph_cmd_start=`date +%s.%N`

# I got this line from AWS sudo bashrc
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Constants
ECHO_LIGHT_GREY='\033[0;37m'
ECHO_DARK_GREY='\033[1;30m'
ECHO_NO_COLOR='\033[0m'

missing=()

if [ -d "$HOME/bin" ]; then
  export PATH=$HOME/bin:$PATH
fi
if [ -d "$HOME/.local/bin" ]; then
  export PATH=$HOME/.local/bin:$PATH
fi
if [ -d "/usr/local/sbin" ]; then
  export PATH=/usr/local/sbin:$PATH
fi

# Check window size after every command. If necessary, updates the values of LINES and COLUMNS.
shopt -s checkwinsize
# History size
HISTSIZE=10000
HISTFILESIZE=20000
# Ignore and delete duplicate bash history entries.
export HISTCONTROL=ignoredups:erasedups
# Append to the history file, don't overwrite it
shopt -s histappend
# Print timestamp when showing history
export HISTTIMEFORMAT="%F %T "

if [ "$(uname)" == "Darwin" ]; then  # Mac
  export CLICOLOR=1
  export BASH_SILENCE_DEPRECATION_WARNING=1  # Disable the ZSH warninig.
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  alias ls="ls --color=auto"
  alias open='nautilus . > /dev/null 2>&1 &'
else
  missing+=("LS coloring")
fi

alias grep='grep --color=always'

alias s='screen'
alias ll='ls -l'
alias la='ls -al'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ...'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias lst='python ~/dev/dotfiles/ls_tests.py'

# Grep Recursive
alias gr='grep -RnIf /dev/stdin . <<<'

# File Find: look for files or directories by name (wildcard).
#   $1: name/patter(bash).
#   $2: optional root path.
ffind () {
  if [ "$2" ]; then
    find "$2" -name "*$1*"
  else
    find . -name "*$1*"
  fi
}

# Ignore case completition.
bind "set completion-ignore-case on"
# Displays all possibilities with only one TAB press.
bind "set show-all-if-ambiguous on"
# Use Sublime Text as the default editor.
export EDITOR="vim"

if [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
else
  missing+=("bash-completion")
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# GIT

git_add_part () {
  git add --patch "$1"
}

# Commits all modified files.
# TODO: support an optional message for the commit.
git_commit_all () {
  files_to_commit=`git status -s | awk '{if ($1 == "M") print $2}' | paste -s -d' ' -`
  gc $files_to_commit
}

alias ga="git add"
alias gb="git branch"
alias gc="git commit -m 'autocommit' ${@:2}"
alias gd="git diff"
alias gs="git status"
alias gt="git stash"
alias gca=git_commit_all
#alias gap=git_add_part
#alias gcp=git_add_part
alias gco="git checkout"
#alias gst="git stash"
alias gsync="git fetch origin && git rebase origin/master"

if [ -f /usr/share/bash-completion/completions/git ]; then
  source /usr/share/bash-completion/completions/git
elif [ -f ~/.git-completion.bash ]; then
  source ~/.git-completion.bash
else
  missing+=("git-completion.bash")
  # curl https://raw.github.com/git/git/master/contrib/completion/git-completion.bash -OL
fi

if [ -f ~/.git-prompt.sh ]; then
  source ~/.git-prompt.sh
else
  missing+=("git-prompt")
  # curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -OL
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Homebrew

brew_completion () {
  if [ -f `brew --repository`/Library/Contributions/brew_bash_completion.sh ]; then
    source `brew --repository`/Library/Contributions/brew_bash_completion.sh
  else
    missing+=("brew-bash")
  fi
}

vagrant_completion () {
  if [ -f `brew --prefix`/etc/bash_completion.d/vagrant ]; then
    source `brew --prefix`/etc/bash_completion.d/vagrant
  else
    missing+=("vagrant")
  fi
}

command -v brew >/dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
  export PATH=$HOME/homebrew/bin:$PATH
  export LD_LIBRARY_PATH=$HOME/homebrew/lib:$LD_LIBRARY_PATH
  brew_completion
  vagrant_completion
fi

if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pinterest
# if [ -f ~/.bash_pinterest.sh ]; then
#   source ~/.bash_pinterest.sh
# else
#   missing+=("bash_pinterest")
# fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh

function preexec_promt_stats() {
  datetime_local=`date "+%Y-%m-%d %H:%M:%S"`
  datetime_utc=`date -u "+%Y-%m-%d %H:%M:%S"`
  datetime_est=`TZ=":US/Eastern" date "+%Y-%m-%d %H:%M:%S"`
  datetime_pst=`TZ=":US/Pacific" date "+%Y-%m-%d %H:%M:%S"`
  echo -e "${ECHO_LIGHT_GREY}[${datetime_local} local] [${datetime_utc} UTC] [${datetime_est} EST] [${datetime_pst} PST]${ECHO_NO_COLOR}"

  fph_cmd_start=`date +%s.%N`
}

function precmd_promt_stats() {
  # TODO maybe append the return value of whatever was called before ($?)

  fph_cmd_end=`date +%s.%N`
  runtime=$(echo "$fph_cmd_end - $fph_cmd_start" | bc -l)

  datetime_local=`date "+%Y-%m-%d %H:%M:%S"`
  datetime_utc=`date -u "+%Y-%m-%d %H:%M:%S"`
  datetime_est=`TZ=":US/Eastern" date "+%Y-%m-%d %H:%M:%S"`
  datetime_pst=`TZ=":US/Pacific" date "+%Y-%m-%d %H:%M:%S"`
  echo -e "${ECHO_LIGHT_GREY}[${datetime_local} local] [${datetime_utc} UTC] [${datetime_est} EST] [${datetime_pst} PST][$runtime seconds]${ECHO_NO_COLOR}"
}


if [ -f ~/.bash-preexec.sh ]; then
  preexec_functions+=(preexec_promt_stats)
  precmd_functions+=(precmd_promt_stats)
else
  echo "Promt timestampt not configured. Use PROMPT_COMMAND or install bash-preexec"
fi

function perforce_client() {
  pwd | awk -F '/' '{
    n = split($0,a,"/");
    if (n < 6) {
      exit;
    }
    if ( a[2] == "google" && a[3] == "src" && a[4] == "cloud" ) {
      if ( a[5] == "fabriph" )
        print a[6];
      else
        print a[5],"@",a[6];
    }
}'
}

# TODO(fabriph):replace by a front matching, printing the rest of the array,
# until it's long.
function my_ps_dir() {
  pwd | awk -F  "/"  '{
    FS = OFS = "/"
    sub(ENVIRON["HOME"], "~");
    if (length($0) > 24 && NF > 5) {
      if ( $4 == "cloud" ) {
        if (NF == 6)
          exit;
        else if (NF == 7)
          print "/"$7
        else if (NF == 8)
          print "/"$7,$8
        else if (NF == 9)
          print "/"$7,$8,$9
        else
          print "/"$7,"...",$(NF-1),$NF
      } else {
        print $1,$2,"...",$(NF-1),$NF
      }
    } else
      print $0
  }'
}

grey=$(tput setaf 0)  # In fact is black
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
pink=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
bold=$(tput bold)
reset=$(tput sgr0)

ps1_user=$USER
ps1_user_color="$green"
if [ "$(uname)" == "Darwin" ]; then  # Mac
  # Switch on serial number
  # serial="$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')"
  # i=$((${#serial}-3))
  # if [ "${serial:$i:3}" == "R53" ]; then  # Mac personal
  #   ps1_user_color="$green"
  # elif [  "${serial:$i:3}" == "VDL" ]; then  # Mac G
  #   ps1_user="Mac"
  #   #ps1_user_color="$cyan"
  # else  # Unkown Mac
  ps1_user="Mac"
  ps1_user_color="$green"
  # fi
else
  # Linux & others
  node=`uname --nodename | cut -f2 -d'.'`
  if [ "$node" == "nyc" ] || [ "$node" == "c" ]; then
    ps1_user="$node"
    ps1_user_color="$pink"
  elif [ "$node" == "penguin" ]; then
    ps1_user="ChromeOS"
    ps1_user_color="$green"
  else  # Uknown Linux
    ps1_user="$node"
    ps1_user_color="$pink"
  fi
  # ps1_user_color="$pink"
fi

# Custom PS1:
command -v __git_ps1 >/dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
  # Path compression is temporarely disabled (`$(my_ps_dir)` vs `\w`)

  # PS1 Git
  PS1='\[$ps1_user_color\]$ps1_user\[$reset\]:\[$blue$bold\]\w\[$grey\]$(__git_ps1 " %s")\[$reset\]\$ '

  # PS1 Git + Perforce
  #PS1='\[$ps1_user_color\]$ps1_user\[$reset\]:\[$cyan\]$(perforce_client)\[$blue$bold\]\w\[$grey\]$(__git_ps1 " %s")\[$reset\]\$ '
else
  PS1='\[$ps1_user_color\]$ps1_user\[$reset\]:\[$blue$bold\]\w\[$reset\]\$ '
  missing+=("__git_ps1")
fi

# Try colors:
#PS1='\[$grey\]grey\[$red\]red\[$green\]green\[$yellow\]yellow\[$blue\]blue\[$pink\]pink\[$cyan\]cyan\[$white\]white\[$bold\]\[$grey\]grey\[$red\]red\[$green\]green\[$yellow\]yellow\[$blue\]blue\[$pink\]pink\[$cyan\]cyan\[$white\]white\[$reset\]'


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NVM

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Show missing files
if [ ! ${#missing[@]} -eq 0 ]; then
  output=$(printf ", %s" "${missing[@]}")
  output=${output:1}
  echo "bashrc.sh: missing ${output[*]}"
else
  echo "bashrc.sh: nothing missing"
fi

bashrc_end=`date +%s.%N`
runtime=$(echo "$bashrc_end - $bashrc_start" | bc -l)
echo "bashrc.sh: loaded in $runtime seconds"
