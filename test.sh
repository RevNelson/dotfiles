while getopts 'm:' flag; do
    case "${flag}" in
        m) IFS=: read -a DATABASE <<< "$OPTARG" ;;
    *)
        echo "FAIL"
        exit 1
        ;;
    esac
done

echo "${DATABASE[4]}"

if [ ! -z DATABASE ]; then
    if [ ! -z "${DATABASE[4]}" ]; then
        echo "HAS SSL"
    fi
fi

for item in "${DATABASE[@]}"; do
echo $item
done
