#!/bin/bash

# 导入日志工具
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "命令 '$1' 未找到，请先安装"
        return 1
    fi
}

# 检查依赖工具
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! check_command "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "缺少必要的依赖: ${missing[*]}"
        return 1
    fi
}

# 清理构建目录
clean_build_dir() {
    local build_dir=$1
    if [ -d "$build_dir" ]; then
        info "清理构建目录: $build_dir"
        rm -rf "$build_dir"
    fi
}

# 读取配置文件
read_config() {
    local config_file=$1
    local key=$2
    
    if [ ! -f "$config_file" ]; then
        error "配置文件不存在: $config_file"
        return 1
    fi
    
    jq -r "$key" "$config_file"
}