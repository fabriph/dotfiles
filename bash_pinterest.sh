
# Log all commands to syslog
function log2syslog {
  declare command
  if (($(history | wc -l) > 1));  then
      command=$(fc -ln -0)
      logger -p local1.notice -t bash -i -- $USER $SUDO_USER: $command
  fi
}
trap log2syslog DEBUG
