# TODO:
#  - Be able to install it as a remote curl, something like curl -fsSL https://raw.githubusercontent.com/supermarin/Alcatraz/master/Scripts/install.sh | sh
#  - If system is OSX use some naming, otherwise use regular Linux naming (example .bash_profile showuld be .profile).
#  - use pwd + local references so we dont need to always checkout this repo on ~/dev/scripts.
#  - If files are already there, ask if wanna remplace them.
#  - Add the option to keep old files and then easily restore them, just in case I wanna use this install.sh as a temporary fix on somebody else computer.
ln -s ~/dev/scripts/linux-config-files/bash_profile ~/.bash_profile
ln -s ~/dev/scripts/linux-config-files/vimrc ~/.vimrc
ln -s ~/dev/scripts/linux-config-files/git/git-prompt.sh ~/.git-prompt.sh
ln -s ~/dev/scripts/linux-config-files/git/git-completion.bash ~/.git-completion.bash
ln -s ~/dev/scripts/linux-config-files/sublime/settings ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User/Preferences.sublime-settings
ln -s ~/dev/scripts/linux-config-files/sublime/keyboard ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User/Default\ \(OSX\).sublime-keymap

