#!/bin/bash
# Usage:
#   If you want to activate the work related features, create a '.at-work' file in home folder.
#   If you want to include additional configs, and do not version them, create a ~/.bash_extended_profile file and put them there.

# Peding things to code
# - Improve TAB compeltion:
#   - http://stackoverflow.com/questions/10942919/customize-tab-completion-in-shell
#   - http://superuser.com/questions/289539/custom-bash-tab-completion
# - iReset with no parameter may trigger something like 'history | grep "^(iatsReset|iReset|ireset).*$" | peco'.

missing=()

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

HISTSIZE=5000
export HISTCONTROL=ignoredups:erasedups

alias ..='cd ..'
alias grep='grep --color=always'

if [ "$(uname)" == "Darwin" ]; then
  export CLICOLOR=1
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  alias ls="ls --color=auto"
else
  missing+=("LS coloring")
fi
alias l='ls -CF'
alias la='ls -a'
alias ll='ls -l'
# Grep Recursive
alias gr='grep -RnIf /dev/stdin . <<<'

# Name Find: look for files or directories by name.
#   $1: name/patter(bash).
#   $2: optional root path.
function nfind {
  if [ "$2" ]; then
    find "$2" -name "$1"
  else
    find . -name "$1"
  fi
}

# Ignore case completition.
bind "set completion-ignore-case on"
# Displays all possibilities with only one TAB press.
bind "set show-all-if-ambiguous on"

if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
else
  missing+=("Bash completion")
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# GIT
alias gc="git commit"

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
else
  missing+=("git-completition")
fi

if [ -f ~/.git-prompt.sh ]; then
  source ~/.git-prompt.sh
else
  missing+=("git-prompt")
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt
command -v __git_ps1 >/dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
    PS1='\[$green$bold\]\u\[$reset\]:\[$blue$bold\]\w\[$grey\]$(__git_ps1 " %s")\[$reset\]\$ '
else
    PS1='\[$green$bold\]\u\[$reset\]:\[$blue$bold\]\w\[$reset\]\$ '
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Optional Homebrew stuff
export PATH=/usr/local/sbin:$PATH

command -v brew >/dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
  if [ -f `brew --repository`/Library/Contributions/brew_bash_completion.sh ]; then
    . `brew --repository`/Library/Contributions/brew_bash_completion.sh
  else
    missing+=("brew bash completion")
  fi
  if [ -f `brew --prefix`/etc/bash_completion.d/vagrant ]; then
    source `brew --prefix`/etc/bash_completion.d/vagrant
  else
    missing+=("brew vagrant completion")
  fi
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff used at work
# In order to avoid bash environment pollution, this is not included unless a '.at-work' file exists in home folder.
# TODO: replace repeated commands by a ignore case aliases, couldn't get that working right now.
if [ -f ~/.at-work ]; then
  alias ibranch=iatsBranch
  alias ibranchSubmodule=iatsBranchSubmodule
  alias imerge=iatsMerge
  alias ipull=iatsPull
  alias ipush=iatsPush
  alias isql=iatsSql
  alias istatus=iatsStatus

  # Git Commit Mobile Core: used every time the submodule is uptade.
  alias gcMobileCore='git commit MobileCore -m "Updated link to submodule."'
  alias gcmobileCore=gcMobileCore

  # Git Commit Done: used every time a case is finished.
  #   $1: message.
  #   $2: case ID. If not set, It will parse the one form the current branch.
  function gcDone {
    if [ "$2" ]; then
      caseID="$2"
    else
      caseID=`echo $(__git_ps1 " %s") | sed -E "s/^T([1234567890]+).*$/\1/"`
    fi
    if [ "$caseID" ]; then
      if [ "$1" ]; then
        git commit --allow-empty -m "Fix: T#$caseID: $1"
      else
        git commit --allow-empty -m "Fix: T#$caseID: done."
      fi
    else
      echo "Coudln't get case ID."
    fi
  }
  alias gcdone=gcDone

  # Iats Switch: Easily exchange between local branches.
  function iSwitch {
    #  iatsSwitch `iatsListBranches | cut -d"/" -f 2 | peco`
    if [ "$#" -eq 0 ]; then
      target=`git branch | awk -F ' +' '! /\(no branch\)/ {print $2}' | peco`
      if [ "$target" ]; then
        iatsSwitch "$target"
      fi
    else
      iatsSwitch "$@"
    fi
  }
  alias iswitch=iSwitch

  function iListTests {
    vim `find . -name "*unit.cpp" | peco`
  }
  alias ilistTests=iListTests

  function ireset {
    target=`echo -e "<Empty>\nmobile_EventModule\nmobile_MobileUiTests\n<Exit>" | peco`
    if [ "$target" == "<Empty>" ]; then
      iatsReset
    elif [ "$target" == "<Exit>" ]; then
      return
    else
      iatsReset -s "$target"
    fi
  }

  alias bt="./tools/buildTests"
  alias rt="./bin/runTests"
else
  missing+=(".at-work")
fi

# Show missing files
if [ ! ${#missing[@]} -eq 0 ]; then
  output=$(printf ", %s" "${missing[@]}")
  output=${output:1}
  echo "Missing: ${output[*]}"
fi

# Import extended config
if [ -f ~/.bash_extended_profile ]; then
  . ~/.bash_extended_profile
fi

