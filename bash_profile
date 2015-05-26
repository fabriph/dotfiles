# Peding things to code
# - Use functions for magic stuff
#   - lll () { /bin/ls -aOle "$@" | /usr/bin/more ; }
# - Use an IF to automatically detect if OS X or Linux, to enable ls coloring on each one.
# - Improve TAB compeltition:
#   - http://stackoverflow.com/questions/10942919/customize-tab-completion-in-shell
#   - http://superuser.com/questions/289539/custom-bash-tab-completion
# - Implement an easily find command, maybe doing the search path optional.

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

alias l='ls -CF'
alias la='ls -a'
alias ll='ls -l'
alias gr='grep -RnIf /dev/stdin . <<<'
function ffind {
  find . -name "$1"
}

# Ignore case completition
bind "set completion-ignore-case on"
# Displays all possibilities with only one TAB press.
bind "set show-all-if-ambiguous on"

# Bash completion
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
else
  echo "Missing bash completion"
fi

# Coloring in command LS.
export CLICOLOR=1  # This one only works in OS X
#alias ls="ls --color=auto"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Optional GIT stuff

alias gc="git commit --allow-empty -m"

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
else
  echo "Missing git-completition"
fi

if [ -f ~/.git-prompt.sh ]; then
  source ~/.git-prompt.sh
else
  echo "Missing git-prompt"
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
  if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
  else
    echo "Missing brew bash completion"
  fi
  if [ -f `brew --prefix`/etc/bash_completion.d/vagrant ]; then
    source `brew --prefix`/etc/bash_completion.d/vagrant
  else
    echo "Missing brew vagrant completion"
  fi
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff used at work
# TODO: replace this by a ignore case aliases, couldn't get that working right now.
alias iBranch=iatsBranch
alias ibranch=iatsBranch
alias iBranchSubmodule=iatsBranchSubmodule
alias ibranchSubmodule=iatsBranchSubmodule
alias iMerge=iatsMerge
alias imerge=iatsMerge
alias iPull=iatsPull
alias ipull=iatsPull
alias iPush=iatsPush
alias ipush=iatsPush
alias iReset=iatsReset
alias ireset=iatsReset
alias iSql=iatsSql
alias isql=iatsSql
alias iStatus=iatsStatus
alias istatus=iatsStatus
alias iSwitch=iatsSwitch
alias iswitch=iatsSwitch
alias gcMobileCore='git commit MobileCore -m "Updated link to submodule."'
alias gcmobileCore='git commit MobileCore -m "Updated link to submodule."'
#function magic {
#  vim `find . -name "*unit.cpp" | peco`
#}
#function i2Switch {
#  iatsSwitch `iatsListBranches | cut -d"/" -f 2 | peco`
#}
alias bt="./tools/buildTests --mock-server"
alias rt="./bin/runTests"
