#!/bin/bash

# Parameters
filename="$1"
output="${2:-Spool-Weight}"

echo "Compiling file: $filename"
echo ""

line_pattern='(include|use)\s*<(.+?)>'
comment_pattern='^\s*//'

pathRoot=$(dirname "$0")
dependencies=()

echo "$pathRoot"

search_file_dependencies() {
    local path="$1"
    local filenames=()

    while IFS= read -r line; do
        if [[ "$line" =~ $line_pattern ]] && [[ ! "$line" =~ $comment_pattern ]]; then
            filenames+=("${BASH_REMATCH[2]}")
        fi
    done < "$path"

    echo "${filenames[@]}"
}

discover_scadfile_dependencies() {
    local path="$1"
    local depth="${2:-0}"
    local root_dir
    root_dir=$(dirname "$path")

    local deps
    deps=$(search_file_dependencies "$path")
    for dep in $deps; do
        dependencies+=("$(realpath "$pathRoot/$root_dir/$dep"):$((depth + 1))")
        discover_scadfile_dependencies "$root_dir/$dep" $((depth + 1))
    done
}

discover_dependencies() {
    local path="$1"
    discover_scadfile_dependencies "$path"
    printf "%s\n" "${dependencies[@]}" | sort -t: -k2 -nr | cut -d: -f1 | uniq
}

concat_scadfile() {
    local path="$1"
    local outputPath="$2"
    local name="// $(basename "$path")"

    {
        echo "// =============="
        echo "$name"
        echo "// =============="

        while IFS= read -r line; do
            if [[ ! "$line" =~ $line_pattern ]]; then
                echo "$line"
            fi
        done < "$path"
    } >> "$outputPath"
}

dependencies=$(discover_dependencies "$filename")
dependencies+=" $(realpath "$pathRoot/$filename")"

dateTag=$(date +%Y%m%d)
outputFolder=$(realpath "$pathRoot/output/")
outputPath=$(realpath "$pathRoot/output/$output-$dateTag.scad")

mkdir -p "$outputFolder"

if [[ -f "$outputPath" ]]; then
    rm "$outputPath"
fi

echo "Order of files to compile:"
for dep in $dependencies; do
    echo "  $dep"
    concat_scadfile "$dep" "$outputPath"
done

echo "Done. Written to $outputPath"