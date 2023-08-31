#!/bin/bash

# 指定多语言文件和项目文件所在的目录
PROJECT_DIR=/Users/tomodel/Desktop/work/iOS/mexo-ios/Mexo/Mexo/

LOCALIZATION_DIR=/Users/tomodel/Desktop/work/iOS/mexo-ios/Mexo/Mexo/Tool/GlobalLanguage


function process_file {
    local file="$1"

    while IFS= read -r line; do
        regex1='@"([^"]+)".appLocals'
        regex2='LocalizedString\(@"([^"]+)"\)'
        regex3='value="([^"]+)"'
        
        if [[ $line =~ $regex1 ]]; then
            line_directory "$line" "$regex1" "$regex1" "$regex2" "$regex3" 
        elif [[ $line =~ $regex2 ]]; then
            line_directory "$line" "$regex2" "$regex1" "$regex2" "$regex3" 
        elif [[ $line =~ $regex3 ]]; then
            line_directory "$line" "$regex3" "$regex1" "$regex2" "$regex3" 
        fi

    done < "$file"
}

function line_directory {

    local code="$1"
    local regex="$2"
    local regex1="$3"
    local regex2="$4"
    local regex3="$5"

    while [[ $code =~ $regex ]]; do
        key="${BASH_REMATCH[1]}"
        if [ -n "$key" ]; then
            if ! grep -q "^$key$" "use_keys.txt"; then
                echo "$key" >> "use_keys.txt"
            fi
        fi

        if [ $regex = $regex1 ]; then
            code="${code#*.appLocals*}"
        elif [ $regex = $regex2 ]; then
            code="${code#*LocalizedString}"
        elif [ $regex = $regex3 ]; then
            code=""
        fi
    done
}



function traverse_directory {
    local directory="$1"

    for file in "$directory"/*.m "$directory"/*.mm "$directory"/*.xib; do
        if [[ -f "$file" ]]; then
            process_file "$file"
        fi
    done

    for subdirectory in "$directory"/*; do
        if [[ -d "$subdirectory" ]]; then
            traverse_directory "$subdirectory"
        fi
    done
}

function extract_localization_strings {
    echo "--------------- need_delete_keys start check ---------------"
    localization_dir="$1"
    # 查找所有的.lproj文件并提取所有的本地化字符串
    find "$localization_dir" -name "*.lproj" -print0 | while IFS= read -r -d '' dir
    do

        lproj_dir="${dir##*/}"
        lproj_name="${lproj_dir%.lproj}"
        saveName="${lproj_name}_allKeys.txt"
        echo > "$saveName"

        file="$dir/Localizable.strings"

        while IFS= read -r line; do

            IFS='=' read -ra ADDR <<< "$line"
            echo "line: $line"
            if [[ ${#ADDR[@]} -ge 2 ]]; then
                key="${ADDR[0]}"
                key=$(echo $key | tr -d '"')
                echo "key: $key"

                if [[ ! $key =~ ^[0-9]+$ ]]; then
                    
                    if ! grep -q "^$key$" "use_keys.txt"; then

                        # echo "$key" >> "need_delete_keys.txt"
                        echo "$key" >> "$saveName"

                        # if ! grep -q "^$key$" "need_delete_keys.txt"; then
                        #     echo "$key" >> "need_delete_keys.txt"
                        # fi
                        #删除
                        sed -i '' "/$line/d" "$file"
                    fi
                fi
                
            fi
        done < "$file"
    done
    echo "--------------- need_delete_keys end check ---------------"
}

# 清空需要删除的键文件
> need_delete_keys.txt
# 所有定义的key
> all_keys.txt
# 所有使用的key
> use_keys.txt

echo "--------------- 获取所有使用到的key  start ---------------"
# 获取所有使用到的key
traverse_directory "$PROJECT_DIR"
echo "--------------- 获取所有使用到的key  end ---------------"


echo "--------------- 获取定义的key start  ---------------"

extract_localization_strings "$LOCALIZATION_DIR"

echo "--------------- 获取定义的key end  ---------------"