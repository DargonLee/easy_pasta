#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../../common/utils.sh"

build_linux() {
    local config_file=$1
    
    # 检查依赖
    check_dependencies "flutter" "dpkg-deb" || exit 1
    
    # 读取配置
    local app_name=$(read_config "$config_file" '.app.name')
    local version=$(read_config "$config_file" '.app.version')
    local output_dir=$(read_config "$config_file" '.build.outputDir')
    
    info "开始构建 Linux 版本..."
    
    # 构建应用
    flutter build linux --release || {
        error "Linux构建失败"
        return 1
    }
    
    # 创建deb包
    info "创建DEB安装包..."
    create_deb_package "$app_name" "$version" "$output_dir/linux" || {
        error "DEB包创建失败"
        return 1
    }
    
    info "Linux构建完成"
}

create_deb_package() {
    local app_name=$1
    local version=$2
    local output_dir=$3
    
    mkdir -p "$output_dir/debian/DEBIAN"
    cat > "$output_dir/debian/DEBIAN/control" << EOF
Package: $app_name
Version: $version
Section: utils
Priority: optional
Architecture: amd64
Maintainer: $(read_config "$config_file" '.app.publisher')
Description: $(read_config "$config_file" '.app.description')
EOF

    dpkg-deb --build "$output_dir/debian" "$output_dir/$app_name-$version.deb"
}