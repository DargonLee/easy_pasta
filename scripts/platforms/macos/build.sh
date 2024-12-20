#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../../common/utils.sh"

build_macos() {
    local config_file=$1
    
    # 检查依赖
    check_dependencies "flutter" "create-dmg" || exit 1
    
    # 读取配置
    local app_name=$(read_config "$config_file" '.app.name')
    local version=$(read_config "$config_file" '.app.version')
    local output_dir=$(read_config "$config_file" '.build.outputDir')
    
    info "开始构建 macOS 版本..."
    
    # 构建应用
    flutter build macos --release || {
        error "macOS构建失败"
        return 1
    }
    
    # 创建DMG
    info "创建DMG安装包..."
    create_dmg \
        --volname "$app_name" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --app-drop-link 600 185 \
        "$output_dir/macos/$app_name-$version.dmg" \
        "$output_dir/macos/Build/Products/Release/$app_name.app" || {
        error "DMG创建失败"
        return 1
    }
    
    info "macOS构建完成"
}