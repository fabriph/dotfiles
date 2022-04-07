script_dir=$(dirname "$0")

while IFS=, read -r col1 col2
do
    echo "trying: $col2"
    ping -c 2 $col1
done < $script_dir/urls.csv

