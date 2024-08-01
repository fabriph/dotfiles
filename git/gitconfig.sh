
[alias]
    stashgrep = "!f() { for i in `git stash list --format=\"%gd\"` ; \
              do git stash show -p $i | grep -H --label=\"$i\" \"$@\" ; done ; }; f"
