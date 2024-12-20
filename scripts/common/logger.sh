#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志级别
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 当前日志级别
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ $level -ge $CURRENT_LOG_LEVEL ]; then
        case $level in
            $LOG_LEVEL_DEBUG)
                echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - ${message}"
                ;;
            $LOG_LEVEL_INFO)
                echo -e "${GREEN}[INFO]${NC} ${timestamp} - ${message}"
                ;;
            $LOG_LEVEL_WARN)
                echo -e "${YELLOW}[WARN]${NC} ${timestamp} - ${message}"
                ;;
            $LOG_LEVEL_ERROR)
                echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}"
                ;;
        esac
    fi
}

debug() { log $LOG_LEVEL_DEBUG "$1"; }
info() { log $LOG_LEVEL_INFO "$1"; }
warn() { log $LOG_LEVEL_WARN "$1"; }
error() { log $LOG_LEVEL_ERROR "$1"; }