#!/bin/bash
# TODO:
#  - Promt to initialize ~/.gitconfig with username and email
#  - Be able to install it as a remote curl, something like curl -fsSL https://raw.githubusercontent.com/supermarin/Alcatraz/master/Scripts/install.sh | sh
#  - Install vimrc for root user.
#  - Remove git completion from the repo and download it every time from git.
#  - Add hosts as a copy, or maybe a softlink?

TRASH_DIR=~/tmp-trash
today=`date +%Y-%m-%d.%H:%M:%S`

# A soft version of rm.
rmsoft () {
    mkdir -p $TRASH_DIR
    mv "$1" "$TRASH_DIR/$(basename $1).$today"
}

handle_backup () {
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

install_package () {
    package="$1"
    origin="$2"
    destination="$3"
    REPLY=""
    while [[ ! $REPLY =~ ^[YyNn]$ ]]
        do
            read -p "Install $package [y/n]? " -n 1 -r
            echo
        done
    if [[ $REPLY =~ ^[Nn]$ ]]
    then
        echo -e "    Skipped\n"
        return
    fi
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
            handle_backup "$destination"
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

install_package "Bash profile (.bashrc)" "$INSTALL_DIR/bashrc.sh" ~/.bashrc
install_package "Bash SSH placebo (.bash_profile)" "$INSTALL_DIR/bash_profile.sh" ~/.bash_profile

install_package "VIM config file" "$INSTALL_DIR/vimrc" ~/.vimrc

install_package "Git prompt" "$INSTALL_DIR/git/git-prompt.sh" ~/.git-prompt.sh
install_package "Git completition" "$INSTALL_DIR/git/git-completion.bash" ~/.git-completion.bash
echo "************************************************************"
echo "TODO https://github.com/fabriph/dotfiles/blob/master/git/gitconfig.sh"
echo "************************************************************"

install_package "screenrc" "$INSTALL_DIR/screenrc" ~/.screenrc


## Sublime ##

# Sublime - Mac
if [ -d ~/Library/Application\ Support/Sublime\ Text ]; then
  install_package "Sublime config" "$INSTALL_DIR/sublime/settings" ~/Library/Application\ Support/Sublime\ Text/Packages/User/Preferences.sublime-settings
  install_package "Sublime keyboard" "$INSTALL_DIR/sublime/keyboard" ~/Library/Application\ Support/Sublime\ Text/Packages/User/Default\ \(OSX\).sublime-keymap
  echo "You may want to run: sudo ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl"
fi

# Sublime 3 - Mac
if [ -d ~/Library/Application\ Support/Sublime\ Text\ 3 ]; then
  install_package "Sublime 3 config" "$INSTALL_DIR/sublime/settings" ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings
  install_package "Sublime 3 keyboard" "$INSTALL_DIR/sublime/keyboard" ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ \(OSX\).sublime-keymap
  echo "You may want to run: sudo ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl"
fi

# Sublime 3 - Linux
if [ -d ~/.config/sublime-text-3 ]; then
  install_package "Sublime 3 config" "$INSTALL_DIR/sublime/settings" ~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings
  install_package "Sublime 3 keyboard" "$INSTALL_DIR/sublime/keyboard" ~/.config/sublime-text-3/Packages/User/Default\ \(Linux\).sublime-keymap
fi

echo "You may want to run: ln -s ~/dev/dotfiles/intellij/pycharm-keyboard.xml ~/Library/Application\ Support/JetBrains/PyCharmCE2024.1/keymaps/pycharm-keyboard.xml"
