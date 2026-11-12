#!/usr/bin/env bash
# 本地构建运行镜像：先编译前端 + 后端，再按 Dockerfile 约定的布局放进 dist/<arch>/。
#
# Dockerfile 只接收预编译二进制（dist/${TARGETARCH}/secops），不在镜像里编译，
# 所以本脚本负责把它准备好。install.sh / update.sh 在镜像拉取失败时也调用它。
#
#   ./build-image.sh                    构建 secops:latest
#   SECOPS_IMAGE=secops SECOPS_TAG=dev ./build-image.sh
set -euo pipefail
cd "$(cd "$(dirname "$0")" && pwd)"

info(){ printf '\033[36m[*]\033[0m %s\n' "$*"; }
die(){  printf '\033[31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

command -v go  >/dev/null 2>&1 || die "需要 Go（>=1.26）：https://go.dev/dl/"
command -v npm >/dev/null 2>&1 || die "需要 Node.js / npm 构建内嵌前端"
command -v docker >/dev/null 2>&1 || die "需要 docker"

img="${1:-${SECOPS_IMAGE:-secops}:${SECOPS_TAG:-latest}}"

info "编译前端与后端（./build.sh）…"
./build.sh

arch="$(uname -m)"
case "$arch" in
  x86_64|amd64)  arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) die "不支持的架构：$arch（请自行交叉编译后放入 dist/$arch/secops）" ;;
esac

binary="dist/secops-linux-${arch}/secops"
[ -f "$binary" ] || die "未找到编译产物 $binary"
mkdir -p "dist/${arch}"
cp "$binary" "dist/${arch}/secops"
info "构建镜像 ${img}…"
docker build -t "$img" .
info "完成：${img}（docker compose up -d 即可启动）"
