# Simple code syntax for Objective C.
# Fabricio PH  http://fabricioph.com
TMP_FILE='temp.syntax-style'

## Pointers
# Removes right spaces.
sed "s-\*[ 	]*-\*-" $1 > $TMP_FILE
# Normalizes left spaces.
sed -i '' "s-\([^(][^ 	]*\)[ 	]*\*\([^)]\)-\1 \*\2-" $TMP_FILE

## METHOD DECLARATION
# Normalizes spaces in method return type: '   -   (void)    method' -> '- (void)method'
sed -i '' "s,^[ 	]*-[ 	]*(\([^)]*\))[ 	]*,- (\1)," $TMP_FILE
# Normalize spaces after colon in method signature
sed -i '' "s,\(^[ 	]*-.*\)[ 	]*:[ 	]*\(.*[ 	]*{\),\1:\2,g" $TMP_FILE
# Normalize spaces after closing parentesis for parameter tipe: "call:(type) var" -> "call:(type)var"
sed -i '' "s,\(^[ 	]*-.*:[ 	]*([^)]*)\)[ 	]*\(.*[ 	]*{\),\1\2,g" $TMP_FILE
# Exactly one space before opening { on method declaration
sed -i '' "s,\(^[ 	]*-.*[^ 	]\)[ 	]*{,\1 {," $TMP_FILE

## METHOD CALLING
# Removing spaces after [ and before ]
sed -i '' "s,^\([ 	]*\[\)[ 	]*\([^ 	].*[^ 	]\)[ 	]*\\(].*\)$,\1\2\3,g" $TMP_FILE

# Normalize spaces around '+' '/' '=' '=='
# '-' and '*' needs a more complex regex)
#echo -e "\nrun 5"
#OPERANDS='+/='
#sed "s,[$OPERANDS],AAAA," $TMP_FILE

cat $TMP_FILE

rm $TMP_FILE

