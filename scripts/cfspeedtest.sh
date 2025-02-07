#!/usr/bin/env bash

# CloudflareSpeedTest
# https://github.com/XIU2/CloudflareSpeedTest
#

set -euo pipefail

# PROJ_URL
PROJ_URL="https://github.com/idevsig/cfdns/raw/refs/heads/main"
CN_PROJ_URL="https://framagit.org/idev/cfdns/-/raw/main"

IP_DATA_URL=""
IP_DATA_URL_CLOUDFLARE="https://www.cloudflare.com/ips-v4"
IP_DATA_URL_GCORE_JSON="https://api.gcore.com/cdn/public-ip-list"
IP_DATA_URL_CLOUDFRONT_JSON="https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips"
IP_DATA_URL_AMAZON_JSON="https://ip-ranges.amazonaws.com/ip-ranges.json"

IN_CHINA="" # 是否在中国

CURRENT_EXEC_FILE="/usr/local/bin/cfspeedtest.sh"
API_CDN="https://c.kkgo.cc" # API CDN
RESULT_CSV="result.csv"     # 结果 CSV 文件名

CF_DNS_EXEC="" # CloudflareDNS 脚本文件名
CFST_FILE=""   # CloudflareSpeedTest 二进制文件名

ZONE_TYPE="A" # 记录类型

DOMAIN=""     # 记录域名
PREFIX=""     # 记录前缀

SPEED="2"   # 下载速度默认 2(M)以上
REFRESH=""    # 强制刷新 result.csv
DNS=""        # 刷新 DNS
ONLY=""       # 只刷新指定主机名
SPEED_PORT="" # 速度测试端口
SPEED_URL=""  # 速度测试 URL
EXTEND_STRING="" # 扩展字符串

init_os() {
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    case "$OS" in
    darwin) OS='darwin' ;;
    linux) OS='linux' ;;
    freebsd) OS='freebsd' ;;
        #        mingw*) OS='windows';;
        #        msys*) OS='windows';;
    *)
        echo -e "\033[31mOS $OS is not supported by this installation script\033[0m\n"
        exit 1
        ;;
    esac
}

init_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
    amd64) ARCH="amd64" ;;
    x86_64) ARCH="amd64" ;;
    i386) ARCH="386" ;;
    armv6l) ARCH="armv6l" ;;
    armv7l) ARCH="armv6l" ;;
    aarch64) ARCH="arm64" ;;
    *) 
        echo -e "\033[31mArchitecture $ARCH is not supported by this installation script\033[0m\n"
        exit 1
        ;;
    esac
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

check_in_china() {
    if [ "$(curl -s -m 3 -o /dev/null -w "%{http_code}" https://www.google.com)" != "200" ]; then
        IN_CHINA=1
    fi
}

# 判断是否为 URL 的函数
is_url() {
    local url="$1"
    # 正则表达式匹配 URL
    if [[ "$url" =~ ^https?://[^[:space:]]+ ]]; then
        return 0  # 是 URL
    else
        return 1  # 不是 URL
    fi
}

get_latest_version() {
    repo=${1:-XIU2/CloudflareSpeedTest}

    latest_api_url="https://api.github.com/repos/$repo/releases/latest"
    if [ -n "$IN_CHINA" ]; then
        latest_api_url="${API_CDN}/${latest_api_url//https:\/\/}"
    fi

    doanload_url=$(echo "$repo" | tr -d ' ' | xargs -I {} curl -s "$latest_api_url" | jq -r '.assets[].browser_download_url' | grep "${OS}_${ARCH}")
    if [ -z "$doanload_url" ]; then
        echo -e "\033[31mlatest version not found\033[0m"
        exit 1
    fi

    if [ -n "$IN_CHINA" ]; then 
        doanload_url="${API_CDN}/${doanload_url//https:\/\/}"
    fi
    
    echo "$doanload_url"
}

sudo_check() {
    if [ "$EUID" -ne 0 ]; then
        sudo "$@"
        return
    fi
    "$@"
}

check_cfst_file() {
    _cfst_file_list=("CloudflareSpeedTest" "CloudflareST" "cfst")
    for _cfst_file in "${_cfst_file_list[@]}"; do
        if check_command "$_cfst_file"; then
            CFST_FILE="$_cfst_file"
            break
        fi
    done

    if ! check_command "$CFST_FILE"; then
        cfst_from_compressed
    fi
}

cfst_from_compressed() {
    init_arch
    init_os

    download_url=$(get_latest_version "XIU2/CloudflareSpeedTest")
    # echo "download_url: $download_url"

    savedir=$(mktemp -d -t cfst.XXXXXX)
    packname=$(basename "$download_url")
    fullfilepath="$savedir/$packname"

    # echo "save to: $fullfilepath"
    curl -fsSL -o "$fullfilepath" "$download_url"

    pushd "$savedir" || {
        echo -e "\033[31mcd $savedir error\033[0m"
        exit 1
    }
    tar -zxf "$packname" || {
        echo -e "\033[31mtar -zxf $packname error\033[0m"
        exit 1
    }
    filename="${packname//_*}"
    sudo_check mv "$filename" /usr/local/bin/cfst

    CFST_FILE="cfst"
    popd || exit 1    
}

check_ip_file() {
    if ! check_command "$CFST_FILE"; then
        echo -e "\033[31mcfspeedtest not found\033[0m"
        exit 1
    fi

    local _ip_file="ip.txt"
    
    if [ -z "$IP_DATA_URL" ] && [ ! -f "$_ip_file" ]; then 
        echo -e "\033[31m${_ip_file} not found\033[0m"
        exit 1
    fi


    case "$IP_DATA_URL" in
        "")
            if [ ! -f "$_ip_file" ]; then
                echo -e "\033[31m$_ip_file not found\033[0m"
                exit 1
            fi     
            ;;    
        cf)
            IP_DATA_URL="${API_CDN}/${IP_DATA_URL_CLOUDFLARE//https:\/\/}"
            curl -fsSL -o "$_ip_file" "$IP_DATA_URL"
            ;;
        gc)
            IP_DATA_URL="${API_CDN}/${IP_DATA_URL_GCORE_JSON//https:\/\/}"
            curl -fsSL "$IP_DATA_URL" | jq -r '.addresses[]' > "$_ip_file"
            ;;
        ct)
            IP_DATA_URL="${API_CDN}/${IP_DATA_URL_CLOUDFRONT_JSON//https:\/\/}"
            curl -fsSL "$IP_DATA_URL" | jq -r '.CLOUDFRONT_GLOBAL_IP_LIST[]' > "$_ip_file"
            ;;
        aws)
            IP_DATA_URL="${API_CDN}/${IP_DATA_URL_AMAZON_JSON//https:\/\/}"
            curl -fsSL "$IP_DATA_URL" | jq -r '.prefixes[].ip_prefix' > "$_ip_file"
            ;;
        *)
            echo -e "\033[31mIP data URL $IP_DATA_URL is not supported\033[0m"
            exit 1
            ;;
    esac    

    if [ ! -f "$_ip_file" ]; then
        echo -e "\033[31m$_ip_file not found\033[0m"
        exit 1
    fi
}

check_result_file() {
    # 强制刷新
    if [ -n "$REFRESH" ]; then
        run_cfst
    fi

    # 结果文件不存在
    if [ ! -f "$RESULT_CSV" ]; then
        run_cfst
    fi

    # 获取文件的修改时间（24小时内的文件不刷新）
    if [ -e "$RESULT_CSV" ]; then
        file_mtime=$(stat -c %Y "$RESULT_CSV")  # 获取文件修改时间的时间戳
        current_time=$(date +%s)                # 当前时间的时间戳

        # 计算修改时间与当前时间的差值（单位：秒）
        time_diff=$((current_time - file_mtime))

        # 如果文件修改时间超过 24 小时，运行 `run_cfst`
        if [ $time_diff -gt 86400 ]; then
            run_cfst
        fi
    else
        echo "File $RESULT_CSV does not exist. Running run_cfst..."
        run_cfst
    fi
}

run_cfst() {
    RUN_PARAMS=()

    if [ -n "$SPEED_PORT" ]; then
        RUN_PARAMS+=("-tp" "$SPEED_PORT")
    fi
    if [ -n "$SPEED_URL" ]; then
        RUN_PARAMS+=("-url" "$SPEED_URL")
    fi
    if [ -n "$EXTEND_STRING" ]; then
        RUN_PARAMS+=("$EXTEND_STRING")
    fi

    "$CFST_FILE" "${RUN_PARAMS[@]}" || {
        echo -e "\033[31m$CFST_FILE run failed, please check the log\033[0m"
        exit 1
    }
}

check_cfdns_file() { 
    _cfdns_file_list=("./cfdns.sh" "cfdns.sh" "cfdns")
    # 从列表中查找可执行文件
    for _cfdns_file in "${_cfdns_file_list[@]}"; do
        if check_command "$_cfdns_file"; then
            CF_DNS_EXEC="$_cfdns_file"
            break
        fi
    done

    CF_DNS_PATH="/usr/local/bin/cfdns"
    
    # 如果是相对路径，则将其复制到 /usr/local/bin
    if [[ "$CF_DNS_EXEC" == "./"* ]]; then
        CF_DNS_EXEC="${CF_DNS_EXEC:2}"
        sudo_check cp "$CF_DNS_EXEC" "$CF_DNS_PATH"
        CF_DNS_EXEC="cfdns"
    fi

    # 从 Git 拉取
    if ! check_command "$CF_DNS_EXEC"; then
        if [  -n "$IN_CHINA" ]; then
            PROJ_URL="$CN_PROJ_URL"
        fi
        curl -fsSL -o "$CF_DNS_PATH" "$PROJ_URL/scripts/cfdns.sh"
        sudo_check chmod +x "$CF_DNS_PATH"
        CF_DNS_EXEC="cfdns"
    fi

    # 如果 cfdns not found
    if ! check_command "$CF_DNS_EXEC"; then
        echo -e "\033[31mcfdns not found\033[0m"
        exit 1
    fi    
}

refresh_dns() {
    if [ -z "$DNS" ]; then
        return
    fi

    if [ -z "${CLOUDFLARE_API_KEY:-}" ]; then
        echo -e "\033[31mCLOUDFLARE_API_KEY not found\033[0m"
        exit 1
    fi

    if [ -z "${CLOUDFLARE_EMAIL:-}" ]; then
        echo -e "\033[31mCLOUDFLARE_EMAIL not found\033[0m"
        exit 1
    fi

    if [ -z "${DOMAIN:-}" ]; then
        echo -e "\033[31mDOMAIN not found\033[0m"
        exit 1
    fi

    if [ -z "${PREFIX:-}" ]; then
        echo -e "\033[31mPREFIX not found\033[0m"
        exit 1
    fi

    if [ -n "$ONLY" ]; then
        # 刷新 DNS
        IFS=, read -r ipv4 _ _ _ _ speed < <(sed -n '2p' "$RESULT_CSV")
        if (( $(echo "$speed < $SPEED" | bc -l) )); then
            echo -e "\033[31mspeed too low($speed), please check\033[0m"
            exit 1
        fi        

        "$CF_DNS_EXEC" -a "$CLOUDFLARE_EMAIL" \
            -k "$CLOUDFLARE_API_KEY" \
            -ac set_record \
            -zn "$DOMAIN" -rn "${PREFIX}" -zy "$ZONE_TYPE" -ct "$ipv4"
        return
    fi

    index=0
    while IFS=, read -r ipv4 _ _ _ _ speed; do
        if (( $(echo "$speed < $SPEED" | bc -l) )); then
            break
        fi

        index=$(echo "$index + 1" | bc)

        "$CF_DNS_EXEC" -a "$CLOUDFLARE_EMAIL" \
            -k "$CLOUDFLARE_API_KEY" \
            -ac set_record \
            -zn "$DOMAIN" -rn "${PREFIX}${index}" -zy "$ZONE_TYPE" -ct "$ipv4"
    done < <(tail -n +2 "$RESULT_CSV") 
}

# 处理参数信息
judgment_parameters() {
    # 参数带帮助
    if [ $# -eq 0 ]; then
        if [ "$0" == "bash" ] || [ "$0" == "-bash" ]; then # 无参数，远程，安装
            cat | sudo_check tee "$CURRENT_EXEC_FILE" > /dev/null
            sudo_checkchmod +x "$CURRENT_EXEC_FILE"
        else # 无参数，本地
            show_help
        fi
        return
    fi

    while [[ "$#" -gt '0' ]]; do
        case "$1" in
            '-a' | '--account') 
            # Cloudflare 账号
                shift
                CLOUDFLARE_EMAIL="${1:?"error: Please specify the correct account."}"
                ;;
            '-k' | '--key') 
            # Cloudflare API key
                shift
                CLOUDFLARE_API_KEY="${1:?"error: Please specify the correct api key."}"
                ;;
            '-t' | '--type') 
            # 记录类型
                shift
                ZONE_TYPE="${1:?"error: Please specify the correct zone type."}"
                ;;
            '-e' | '--extend') 
            # 扩展字符串
                shift
                EXTEND_STRING="${1:?"error: Please specify the correct extend string."}"
                ;;
            '-p' | '--prefix') 
            # 记录前缀
                shift
                PREFIX="${1:?"error: Please specify the correct prefix."}"
                ;;
                
            '-d' | '--domain') 
            # 记录域名
                shift
                DOMAIN="${1:?"error: Please specify the correct domain."}"
                # CHECK DOMAIN
                if [[ "$DOMAIN" != *"."* ]]; then
                    echo -e "\033[31mDOMAIN must be a domain name\033[0m"
                    exit 1
                fi
                ;;                
            '-s' | '--speed') 
            # 下载速度下限
                shift
                SPEED="${1:?"error: Please specify the correct speed."}"
                # SPEED >= 0
                if (( $(echo "$SPEED < 0" | bc -l) )); then
                    echo -e "\033[31mSPEED must be greater than or equal to 0\033[0m" 1>&2
                    exit 1
                fi  
                ;;
            '-c' | '--cdn') 
            # API CDN
                shift
                API_CDN="${1:?"error: Please specify the correct cdn."}"
                # CEHCK WEB URL
                if [[ "$API_CDN" != *"/"* ]]; then
                    echo -e "\033[31mAPI_CDN must be a web url\033[0m"
                    exit 1
                fi
                ;;
            '-P' | '--port')
            # 速度测试端口
                shift
                # SPEED_PORT > 0 & < 65535
                SPEED_PORT="${1:?"error: Please specify the correct port."}"
                if (( $(echo "$SPEED_PORT < 0" | bc -l) || $(echo "$SPEED_PORT > 65535" | bc -l) )); then
                    echo -e "\033[31mSPEED_PORT must be greater than or equal to 0 and less than or equal to 65535\033[0m" 1>&2
                    exit 1
                fi                  
                ;;
            '-u' | '--url') 
            # 速度测试 URL
                shift
                SPEED_URL="${1:?"error: Please specify the correct url."}"
                if ! is_url "$SPEED_URL"; then
                    echo -e "\033[31mSPEED_URL must be a valid URL\033[0m" 1>&2
                    exit 1
                fi
                ;;
            '-i' | '--ipurl')
            # IP 数据源 URL
                shift
                IP_DATA_URL="${1:?"error: Please specify the correct url."}"

                # 检查 IP_DATA_URL 是否为非 CF、GC、AWS、CT 的 URL，若为普通 URL，则验证其有效性
                case $IP_DATA_URL in
                    cf|gc|aws|ct)
                        # 如果是 CF、GC、AWS、CT，则无需验证 URL
                        ;;
                    *)
                        # 验证是否为有效 URL
                        if ! is_url "$IP_DATA_URL"; then
                            echo -e "\033[31mIP_DATA_URL must be a valid URL\033[0m" 1>&2
                            exit 1
                        fi
                        ;;
                esac                  
                ;;

            '-r' | '--refresh') 
            # 刷新 dns
                REFRESH="true"
                ;;
            '-n' | '--dns') 
            # 刷新 DNS
                DNS="true"
                ;;
            '-o' | '--only') 
            # 只刷新一个主机名
                ONLY="true"
                ;;

            '-h' | '--help')
                show_help
                ;;
            *)
                echo "$0: unknown option -- $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

# 显示帮助信息
show_help() {
    cat <<EOF
usage: $0 [ options ]

  -h, --help                           print help
  -a, --account <account>              set Cloudflare account
  -k, --key <key>                      set API key
  -t, --type <type>                    set zone type
  -d, --domain <domain>                set domain
  -p, --prefix <prefix>                set prefix
  -s, --speed <speed>                  set download speed
  -c, --cdn <cdn>                      set api cdn
  -i, --ipurl <ip_url>                 set ip url
  -u, --url <url>                      set speed test url
  -P, --port <port>                    set speed test port
  -e, --extend <string>                set extend string
  -r, --refresh                        refresh result.csv
  -n, --dns                            update DNS records 
  -o, --only                           only refresh one host

e.g.: 
  $0 -a user@example.com -k api_key -d example.com -p cf -s 2 -n -o

e.g.:
  export CLOUDFLARE_API_KEY="api_key"
  export CLOUDFLARE_EMAIL="user@example.com"
  $0 -d example.com -p cf -s 2 -n -o
EOF
    exit 0
}

main() {
    judgment_parameters "$@"

    check_in_china

    check_cfst_file

    check_ip_file

    check_result_file

    check_cfdns_file

    refresh_dns
}

main "$@"
