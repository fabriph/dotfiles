# TODO:
#  - Be able to install it as a remote curl, something like curl -fsSL https://raw.githubusercontent.com/supermarin/Alcatraz/master/Scripts/install.sh | sh
#  - If system is OSX use some naming, otherwise use regular Linux naming (example .bash_profile showuld be .profile).
#  - use pwd + local references so we dont need to always checkout this repo on ~/dev/scripts.
#  - Option to restore backup files.
#  - Detect if Sublime 2 or 3.

function rmsoft {
    mkdir -p $TRASH_DIR
    mv "$1" "$TRASH_DIR/$(basename $1).$today"
}

function handle_backup {
    destination="$1"
    if [ -f "$destination.backup" ]; then
        REPLY=""
        while [[ ! $REPLY =~ ^[YyNn]$ ]]
        do
            read -p "  Backup exists, override? (Y/n)" -n 1 -r
            echo
        done
        if [[ $REPLY =~ ^[Nn]$ ]]
        then
            echo "    Backup Skipped"
            rmsoft "$destination"
            return
        else
            rmsoft "$destination.backup"
        fi
    fi
    mv "$destination" "$destination.backup"
    echo "    Backup: $destination.backup"
}

function install_package {
    package="$1"
    origin="$2"
    destination="$3"
    if [ -f "$destination" ]; then
        REPLY=""
        while [[ ! $REPLY =~ ^[BbRrSs]$ ]]
        do
            read -p "$package is present: (R)eplace, (B)ackup, (S)kip? " -n 1 -r
            echo
        done
        if [[ $REPLY =~ ^[Ss]$ ]]
        then
            echo -e "    Skipped\n"
            return
        fi
        if [[ $REPLY =~ ^[Bb]$ ]]
        then
            handle_backup $destination
        fi
        if [[ $REPLY =~ ^[Rr]$ ]]
        then
            rmsoft "$destination"
        fi
    else
        echo "$package:"
    fi
    ln -s "$origin" "$destination"
    echo -e "    Successfully installed\n"
}

INSTALL_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TRASH_DIR=~/.tmp-trash
today=`date +%Y-%m-%d.%H:%M:%S`

install_package "Bash Profile" "$INSTALL_DIR/bash_profile" ~/.bash_profile

install_package "VIM config file" "$INSTALL_DIR/vimrc" ~/.vimrc

install_package "GIT Prompt" "$INSTALL_DIR/git/git-prompt.sh" ~/.git-prompt.sh

install_package "GIT Completition" "$INSTALL_DIR/git/git-completion.bash" ~/.git-completion.bash

if [ -d ~/Library/Application\ Support/Sublime\ Text\ 2 ]; then
  install_package "Sublime config" "$INSTALL_DIR/sublime/settings" ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User/Preferences.sublime-settings

  install_package "Sublime keyboard" "$INSTALL_DIR/sublime/keyboard" ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User/Default\ \(OSX\).sublime-keymap
fi
