# CloudflareDNS

依赖 [**CloudflareSpeedTest**](https://github.com/XIU2/CloudflareSpeedTest) 

## Docker 构建与拉取

### 本地构建
```sh
docker build -t cfdns . -f Containerfile
```

### 使用本项目提供的镜像

| Registry                                                                                          | Image
|---------------------------------------------------------------------------------------------------|----------------------------
| [**Docker Hub**](https://hub.docker.com/r/idevsig/cfdns)                                           | `idevsig/cfdns`
| [**GitHub Container Registry**](https://github.com/idevsig/cfdns/pkgs/container/cfdns)            | `ghcr.io/idevsig/cfdns`
| **Tencent Cloud Container Registry** | `ccr.ccs.tencentyun.com/idevsig/cfdns`

```sh
docker pull idevsig/cfdns:latest

# 或者
docker pull ghcr.io/idevsig/cfdns:latest
```

## 使用 

### Docker 方式

```sh
docker run --rm idevsig/cfdns:latest cfspeedtest -a user@example.com -k api_key -d example.com -p cf -s 5 -n -o
```

#### `docker compose` 方式

1. `docker-compose.yml`
```yaml
services:
  cfdns:
    image: idevsig/cfdns:latest
    container_name: cfdns
    restart: unless-stopped
    environment:
      - CLOUDFLARE_API_KEY=api_key
      - CLOUDFLARE_EMAIL=user@example.com
      - TZ=Asia/Shanghai
    command: ["daemon"]
```

运行
```sh
docker compose up -d
```

2. 设置定时计划
```sh
# 添加定时计划
docker exec cfdns sh -c "echo '15 4 * * * cd /app; cfspeedtest -d example.com -p cf -r -n' | crontab -"

# 停止计划任务
docker exec cfdns pkill crond
# or 强制停止计划任务
docker exec cfdns killall crond

# 重启计划任务
docker exec cfdns pkill -HUP crond
# or
docker exec cfdns pkill crond && crond
```

### 脚本方式（位于文件夹 `scripts`）

```sh
e.g.: 
  ./cfspeedtest.sh -a user@example.com -k api_key -d example.com -p cf -s 2 -n -o

e.g.:
  export CLOUDFLARE_API_KEY="api_key"
  export CLOUDFLARE_EMAIL="user@example.com"
  ./cfspeedtest.sh -d example.com -p cf -s 2 -n -o
```

---

## 帮助

```sh
usage: ./cfspeedtest.sh [ options ]

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
```

> `-h` / `--help`:             帮助信息   
> `-a` / `--account`:          Cloudflare 账号   
> `-k` / `--key`:              Cloudflare API 密钥   
> `-t` / `--type`:             域名主机名类型   
> `-d` / `--domain`:           域名   
> `-p` / `--prefix`:           域名前缀   
> `-s` / `--speed`:            下载速度下限，单位 **`M`**，低于此速度则不记录     
> `-c` / `--cdn`:              API CDN，更新脚本时不需再扶梯     
> `-i` / `--ipurl`:            [`IP 数据源`](https://www.cloudflare.com/ips-v4) URL（以支持 [`GCore`](https://api.gcore.com/cdn/public-ip-list), [`CloudFront`](https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips), [`AWS`](https://ip-ranges.amazonaws.com/ip-ranges.json)）   
> `-P` / `--port`:             速度测试端口   
> `-u` / `--url`:              速度测试 URL   
> `-e` / `--extend`:           扩展参数字符串   
> `-r` / `--refresh`:          强制刷新 result.csv    
> `-n` / `--dns`:              更新 DNS 解析记录   
> `-o` / `--only`:             只刷新一条主机前缀记录   

- `key`, **CLOUDFLARE_EMAIL** 为 CloudFlare 账号
- `account`, [**CLOUDFLARE_API_KEY**](https://dash.cloudflare.com/profile/api-tokens)-> `API Keys` -> `Global API Key`   

---
### 示例说明
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
3. **CloudflareSpeedTest** 其它参数，可通过 `-e` / `--extend` 传递
4. IP 数据源的格式如下，每行一个数据：
```txt
173.245.48.0/20
```

---

## 仓库镜像

- https://git.jetsung.com/idev/cfdns
- https://framagit.org/idev/cfdns
- https://gitcode.com/idev/cfdns
- https://github.com/idevsig/cfdns
  