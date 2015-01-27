# Simple code syntax for Objective C.
# Fabricio PH  http://fabricioph.com
TMP_FILE='temp.syntax-style'

## Pointers
# Removes right spaces.
sed "s-\*[ 	]*-\*-" $1 > $TMP_FILE
# Normalizes left spaces.
sed -i '' "s-\([^(][^ 	]*\)[ 	]*\*\([^)]\)-\1 \*\2-" $TMP_FILE

## METHODS
# Normalizes spaces: '   -   (void)    method' -> '- (void)method'
sed -i '' "s,^[ 	]*-[ 	]*(\([^)]*\))[ 	]*,- (\1)," $TMP_FILE
# Normalize spaces after colon in method signature:
sed -i '' "s,\(^[ 	]*-[ 	]*([^)]*)[ 	]*[^:]*\)[ 	]*:[ 	]*\(([^)]*)\)[ 	]*\([^ 	]*.*{\),\1:\2\3,g" $TMP_FILE

# Normalize spaces around '+' '/' '=' '=='
# '-' and '*' needs a more complex regex)
#echo -e "\nrun 5"
#OPERANDS='+/='
#sed "s,[$OPERANDS],AAAA," $TMP_FILE

cat $TMP_FILE

rm $TMP_FILE

