# CloudflareSpeedTest

[**CloudflareSpeedTest**](https://github.com/XIU2/CloudflareSpeedTest) Docker 版

## 使用本项目提供的镜像

- ghcr.io: https://github.com/idevsig/cfspeedtest/packages
- Docker Hub: https://hub.docker.com/r/jetsung/cfspeedtest

## Docker 构建

### 本地构建
```bash
docker build -t cfst . -f Containerfile
```

### 使用 
```bash
# 使用默认的 ip.txt
docker run --rm cfst

# 确保当前目录下有 ip.txt 文件
# 可从 https://www.cloudflare.com/ips-v4 中提取
docker run --rm -v $(pwd):/app cfst
```