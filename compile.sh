#!/bin/bash

# Parameters
inputFile="$1"
# output="${2:-Spool-Weight}"

echo "Compiling file: $inputFile"
echo ""

line_pattern='(include|use)\s*<(.+?)>'
comment_pattern='^\s*//'

pathRoot=$(dirname "$0")
inputFilename=$(basename "$1")
dependencies=()

function find_dependencies {
    local path=$1
    local file=$2
    local depth=$3

    local nextDepth=$((depth+1))

    while IFS= read -r line; do
        if ! [[ $line =~ $comment_pattern ]] && [[ $line =~ $line_pattern ]]; then
            depFilename="${BASH_REMATCH[2]}"
            filedir=$(dirname "$depFilename")
            depFilename=$(basename "$depFilename")
            if [[ $filedir == "." ]]; then
                dir="$path"
            else
                dir="$path/$filedir"
            fi

            dependencies+=("{\"path\":\"$dir/$depFilename\",\"depth\":$depth}")
            find_dependencies $dir $depFilename $nextDepth
        fi
    done < "$path/$file"
}

function process_file {
    local filepath=$1
    local outputPath=$2
    local customizer=$3

    local srcFilename=$(basename "$filepath")

    echo "======" >> "$outputPath"
    if [[ $customizer == true ]]; then    
        echo "$srcFilename -- parameters" >> "$outputPath"
    else
        echo "$srcFilename" >> "$outputPath"
    fi
    echo "======" >> "$outputPath"

    local write=$customizer

    if [[ $customizer == false ]] && ! grep -q "module __Customizer_Limit__ () {}" "$filepath"; then
        write=true
    fi

    while IFS= read -r line; do
        if [[ $customizer == true ]] && [[ $line == "module __Customizer_Limit__ () {}" ]]; then
            echo "$line" >> "$outputPath"
            break
        elif [[ $customizer == false ]] && [[ $line == "module __Customizer_Limit__ () {}" ]]; then
            write=true
            continue
        fi

        if ! [[ $line =~ $line_pattern ]] && [[ $write == true ]]; then
            echo "$line" >> "$outputPath"
        fi
    done < "$filepath"
}

find_dependencies $pathRoot $inputFile 0

echo "==output=="
outputFilename=$(echo "$inputFilename" | sed 's/\.[^.]*$//')
timestamp=$(date +"%Y%m%d")
outputPath="$outputFilename-$timestamp.scad"

sorted=$(printf "%s\n" "${dependencies[@]}" | jq -s 'sort_by(.depth) | reverse | unique_by(.path) | .[].path')

process_file "$inputFile" "$outputPath" true
for f in $sorted; do
    unquoted=${f//\"/}
    process_file "$unquoted" "$outputPath" false
done
process_file "$inputFile" "$outputPath" false

echo "result written to: $outputPath"
echo "done"