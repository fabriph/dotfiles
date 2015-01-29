# Simple code syntax for Objective C.
# Fabricio PH  http://fabricioph.com
TMP_FILE='temp.syntax-style'

cat $1 > $TMP_FILE

# TODO: use with precaution, this script might edit character inside strings.
# sed -i '' "s,,,g" $TMP_FILE


## GENERAL
# TODO: this can be better done by analyzing different scenarios.
# Removing spaces around ':'
sed -i '' "s,\([^ 	]\)[ 	]*:,\1:,g" $TMP_FILE
sed -i '' "s,:[ 	]*,:,g" $TMP_FILE


## OPERANDS
# Spaces around '=' and '=='
sed -i '' "s;\([^ 	]\)[ 	]*\([=]\{1,\}\)[ 	]*\([^ 	]\);\1 \2 \3;g" $TMP_FILE


## POINTERS
# Removes right spaces.
sed -i '' "s-\*[ 	]*-\*-" $TMP_FILE
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
# Removing double spacing
sed -i '' "s;^\(.*\[.*\)[ 	]\{2,\};\1 ;g" $TMP_FILE
sed -i '' "s;^\([ 	]*[^ 	].*\)[ 	]\{2,\};\1 ;g" $TMP_FILE


## REVERTS (Putting spaces back when suitable)
# Ternary operand like 'condition ? positive : negative'
sed -i '' "s,\([^ 	]\)[ 	]*\?[ 	]*\(.*\)[ 	]*:[ 	]*\(.*\)$,\1 ? \2 : \3,g" $TMP_FILE
# Enums like: 'typedef enum : Type {'
cat $TMP_FILE

rm $TMP_FILE

