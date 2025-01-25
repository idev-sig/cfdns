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
  -s, --speed <speed>                  set download speed
  -c, --cdn <cdn>                      set api cdn
  -n, --dns                            refresh dns
  -o, --only                           only refresh one host

example: 
  ./cfspeedtest.sh -a user@example.com -k api_key -d example.com -p cf -s 50 -n -o
```

## 仓库镜像

- https://git.jetsung.com/idev/cfdns
- https://framagit.org/idev/cfdns
- https://gitcode.com/idev/cfdns
- https://github.com/idevsig/cfdns
  