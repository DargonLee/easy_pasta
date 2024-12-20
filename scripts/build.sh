#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/common/config.json"

source "$SCRIPT_DIR/common/utils.sh"

main() {
    # 检查配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        error "配置文件不存在: $CONFIG_FILE"
        exit 1
    }
    
    # 检查平台
    case "$(uname -s)" in
        Darwin*)    
            source "$SCRIPT_DIR/platforms/macos/build.sh"
            build_macos "$CONFIG_FILE"
            ;;
        Linux*)     
            source "$SCRIPT_DIR/platforms/linux/build.sh"
            build_linux "$CONFIG_FILE"
            ;;
        *)          
            error "不支持的操作系统"
            exit 1
            ;;
    esac
}

main "$@"


# Unix系统
# ./scripts/build.sh

# Windows系统
# scripts\build.bat