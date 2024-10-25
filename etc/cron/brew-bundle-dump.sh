# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7)  OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  *  command to be executed
# *  *  *  *  *  command --arg1 --arg2 file1 file2 2>&1

0 * * * * BREWFILE="/Users/Shared/setup/$(whoami).Brewfile" && [ ! -r $BREWFILE ] || cp "$BREWFILE" "$BREWFILE.$(date +\%u.\%H).bak" && brew bundle dump --file=$BREWFILE --force >/dev/null 2>&1