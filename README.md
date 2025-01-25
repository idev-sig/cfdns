# CloudflareDNS

依赖 [**CloudflareSpeedTest**](https://github.com/XIU2/CloudflareSpeedTest) 

## Docker 构建与拉取

### 本地构建
```sh
docker build -t cfdns . -f Containerfile
```

### 使用本项目提供的镜像

- [**ghcr.io**: https://github.com/idevsig/cfdns/packages](https://github.com/idevsig/cfdns/packages)
- [**Docker Hub**: https://hub.docker.com/r/idevsig/cfdns](https://hub.docker.com/r/idevsig/cfdns)

```sh
docker pull idevsig/cfdns:latest

# 或者
docker pull ghcr.io/idevsig/cfdns:latest
```

## 使用 
```sh
usage: ./cfspeedtest.sh [ options ]

  -h, --help                           print help
  -a, --account <account>              set Cloudflare account
  -k, --key <key>                      set API key
  -t, --type <type>                    set zone type
  -d, --domain <domain>                set domain
  -p, --prefix <prefix>                set prefix
  -f, --force                          force refresh ip.txt
  -r, --refresh                        refresh dns
  -s, --speed <speed>                  (M) set download speed, default: 2
  -c, --cdn <cdn>                      set api cdn
  -n, --dns                            refresh dns
  -o, --only                           only refresh one host

e.g.: 
  ./cfspeedtest.sh -a user@example.com -k api_key -d example.com -p cf -s 2 -n -o

e.g.:
  export CLOUDFLARE_API_KEY="api_key"
  export CLOUDFLARE_EMAIL="user@example.com"
  ./cfspeedtest.sh -d example.com -p cf -s 2 -n
```

> `-h` / `--help`:             帮助信息   
> `-a` / `--account`:          Cloudflare 账号   
> `-k` / `--key`:              Cloudflare API 密钥   
> `-t` / `--type`:             域名主机名类型   
> `-d` / `--domain`:           域名   
> `-p` / `--prefix`:           域名前缀   
> `-f` / `--force`:            强制更新 ip.txt      
> `-r` / `--refresh`:          强制刷新 DNS   
> `-s` / `--speed`:            下载速度下限，单位 **`M`**，低于此速度则不记录   
> `-c` / `--cdn`:              API CDN，更新脚本时不需再扶梯   
> `-n` / `--dns`:              更新 DNS 解析记录   
> `-o` / `--only`:             只刷新一条主机前缀记录   

---
### 案例说明
1. 参数 `-n` 存在，则将取得的结果更新到域名解析记录
2. 若不带 `-o` 参数，则从 `result.csv` 中取得下载速度大于 `-s` 指定的下载速度以上的列表，更新到解析。域名主机前缀为 `-p` + `<ID>`，如以下：
   ```sh
   # result.csv
    IP 地址,已发送,已接收,丢包率,平均延迟,下载速度 (MB/s)
    104.18.31.111,4,4,0.00,169.69,6.36
    103.21.244.82,4,4,0.00,182.95,4.63
    104.19.84.89,4,4,0.00,184.91,3.82
   ```
   ```sh
    export CLOUDFLARE_API_KEY="api_key"
    export CLOUDFLARE_EMAIL="user@example.com"

    ./cfspeedtest.sh -d example.com -p cf -s 4 -n
    # 则会将 104.18.31.111 A 记录到 cf1.example.com   
    #    将 103.21.244.82 A 记录到 cf2.example.com  

    ./cfspeedtest.sh -d example.com -p cf -s 4 -n -o
    # 仅会将 104.18.31.111 A 记录到 cf.example.com   
   ``` 
---

### 使用 **Docker**
```sh
docker run --rm idevsig/cfdns:latest cfspeedtest -a user@example.com -k api_key -d example.com -p cf -s 5 -n -o
```

## 仓库镜像

- https://git.jetsung.com/idev/cfdns
- https://framagit.org/idev/cfdns
- https://gitcode.com/idev/cfdns
- https://github.com/idevsig/cfdns
  