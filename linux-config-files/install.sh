# TODO:
#  - Be able to install it as a remote curl, something like curl -fsSL https://raw.githubusercontent.com/supermarin/Alcatraz/master/Scripts/install.sh | sh
#  - If system is OSX use some naming, otherwise use regular Linux naming (example .bash_profile showuld be .profile).
#  - use pwd + local references so we dont need to always checkout this repo on ~/dev/scripts.
#  - If files are already there, ask if wanna remplace them.
#  - Add the option to keep old files and then easily restore them, just in case I wanna use this install.sh as a temporary fix on somebody else computer.

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
            return
        else
            rm -f "$destination.backup"
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
    fi
    ln -s "$origin" "$destination"
    echo -e "    Successfully installed\n"
}

install_package "Bash Profile" ~/dev/scripts/linux-config-files/bash_profile ~/.bash_profile

install_package "VIM config file" ~/dev/scripts/linux-config-files/vimrc ~/.vimrc

install_package "GIT Prompt" ~/dev/scripts/linux-config-files/git/git-prompt.sh ~/.git-prompt.sh

install_package "GIT Completition" ~/dev/scripts/linux-config-files/git/git-completion.bash ~/.git-completion.bash

install_package "Sublime config" ~/dev/scripts/linux-config-files/sublime/settings ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User/Preferences.sublime-settings

install_package "Sublime keyboard" ~/dev/scripts/linux-config-files/sublime/keyboard ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User/Default\ \(OSX\).sublime-keymap
