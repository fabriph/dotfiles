#!/bin/bash

# TO DO list:
# - Improve TAB compeltion:
#   - http://stackoverflow.com/questions/10942919/customize-tab-completion-in-shell
#   - http://superuser.com/questions/289539/custom-bash-tab-completion
# - webdiff: opens a web browser with the diff among the current branch, and master, or between an optional parameter.
# - use peco to easily merge branches, confirm after selection.
# - Add ../tools/test.php run `../tools/test.php list | peco` or something like that to easily run tests form IATS.
# - Add an easy way to do git stash save -u "Tests for Matrix 1.0".

missing=()

if [ -d "$HOME/bin" ]; then
  export PATH=$HOME/bin:$PATH
fi
if [ -d "/usr/local/sbin" ]; then
  export PATH=/usr/local/sbin:$PATH
fi

# Check window size after every command. If necessary, updates the values of LINES and COLUMNS.
shopt -s checkwinsize

HISTSIZE=5000
export HISTCONTROL=ignoredups:erasedups
# append to the history file, don't overwrite it
shopt -s histappend

if [ "$(uname)" == "Darwin" ]; then
  export CLICOLOR=1
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  alias ls="ls --color=auto"
else
  missing+=("LS coloring")
fi

alias grep='grep --color=always'

alias ll='ls -l'
alias la='ls -al'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ...'

# Grep Recursive
alias gr='grep -RnIf /dev/stdin . <<<'

# Find: look for files or directories by name.
#   $1: name/patter(bash).
#   $2: optional root path.
function ffind {
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
  . /etc/bash_completion
else
  missing+=("bash-completion")
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# GIT
alias gc="git commit -m 'autocommit' ${@:2}"
alias gco="git checkout"
alias gs="git status"

function git_add_part() {
  git add --patch "$1"
}
alias gcp=git_add_part
alias gap=git_add_part

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
else
  missing+=("git-completition")
  # curl https://raw.github.com/git/git/master/contrib/completion/git-copletion.bash -OL
fi

if [ -f ~/.git-prompt.sh ]; then
  source ~/.git-prompt.sh
else
  missing+=("git-prompt")
  # curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -OL
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Homebrew stuff
export PATH=$HOME/homebrew/bin:$PATH
export LD_LIBRARY_PATH=$HOME/homebrew/lib:$LD_LIBRARY_PATH

command -v brew >/dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
  if [ -f `brew --repository`/Library/Contributions/brew_bash_completion.sh ]; then
    . `brew --repository`/Library/Contributions/brew_bash_completion.sh
  else
    missing+=("brew-bash-completion")
  fi
  # if [ -f `brew --prefix`/etc/bash_completion.d/vagrant ]; then
  #   source `brew --prefix`/etc/bash_completion.d/vagrant
  # else
  #   missing+=("brew vagrant completion")
  # fi
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Google
if [ -f ~/.bash_google ]; then
  . ~/.bash_google
else
  missing+=("Google-scripts")
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt
# TODO(fabriph):replace by a front matching, printing the rest of the array,
# until it's long.
function my_ps_dir() {
  pwd | awk -F  "/"  '{
    FS = OFS = "/"
    sub(ENVIRON["HOME"], "~");
    if (length($0) > 24 && NF > 5) {
      if ( $2 == "google" && $3 == "src" && $4 == "cloud" ) {
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
        }
      else
        print $1,$2,"...",$(NF-1),$NF
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

if [ "$(uname)" == "Darwin" ]; then
  ps1_user_color=$cyan  # Mac
else
  ps1_user_color=$green  # Linux
fi

# Normal PS:
#PS1='\[$ps1_user_color$bold\]\u\[$reset\]:\[$blue$bold\]\w\[$reset\]\$ '
# Git PS:
command -v __git_ps1 >/dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
    PS1='\[$ps1_user_color$bold\]\u\[$reset\]:\[$blue$bold\]\w\[$grey\]$(__git_ps1 " %s")\[$reset\]\$ '
else
    PS1='\[$ps1_user_color$bold\]\u\[$reset\]:\[$blue$bold\]\w\[$reset\]\$ '
    missing+=("__git_ps1")
fi
# Custom PS:
#PS1='\[$ps1_user_color\]\u\[$reset\]:\[$blue$bold\]$(my_ps_dir)\[$reset\]\$ '
# Try colors:
#PS1='\[$grey\]grey\[$red\]red\[$green\]green\[$yellow\]yellow\[$blue\]blue\[$pink\]pink\[$cyan\]cyan\[$white\]white\[$bold\]\[$grey\]grey\[$red\]red\[$green\]green\[$yellow\]yellow\[$blue\]blue\[$pink\]pink\[$cyan\]cyan\[$white\]white\[$reset\]'


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Show missing files
if [ ! ${#missing[@]} -eq 0 ]; then
  output=$(printf ", %s" "${missing[@]}")
  output=${output:1}
  echo "Missing: ${output[*]}"
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DEPRECATED: Stuff used at previous jobs.
  # Iats Switch: Easily exchange between local branches.
  # function iswitch {
  #   #  iatsSwitch `iatsListBranches | cut -d"/" -f 2 | peco`
  #   if [ "$#" -eq 0 ]; then
  #     target=`git branch | awk -F ' +' '! /\(no branch\)/ {print $2}' | peco`
  #     if [ "$target" ]; then
  #       iatsSwitch "$target"
  #     fi
  #   else
  #     iatsSwitch "$@"
  #   fi
  # }

  # function iListTests {
  #   vim `find . -name "*unit.cpp" | peco`
  # }

  # function ideleteLocalBranch {
  #   # TODO: remove master from the list.
  #   # TODO: maybe allow the user to delete it remotely:
  #   #   git push origin --delete REMOTE_BRANCH_TO_DELETE
  #   target=`git branch | awk -F ' +' '! /\(no branch\)/ {print $2}' | peco`
  #   if [ "$target" == "" ]; then
  #     return
  #   fi
  #   REPLY=""
  #   while [[ ! $REPLY =~ ^[YyNn]$ ]]
  #   do
  #     read -p "Sure you want to delete $target ? (Y/n)" -n 1 -r
  #     echo
  #   done
  #   if [[ $REPLY =~ ^[Yy]$ ]]; then
  #     git branch -D "$target"
  #   fi
  # }
