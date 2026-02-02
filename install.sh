#!/bin/sh

download_beta=false
download_version=""

while [ $# -gt 0 ]; do
  case "$1" in
    --beta)
      download_beta=true
      shift
      ;;
    --version)
      shift
      [ $# -eq 0 ] && echo "Missing argument for --version" && exit 1
      download_version="$1"
      shift
      ;;
    *)
      echo "Usage: $0 [--beta] [--version <version>]"
      exit 1
      ;;
  esac
done

# ---------- 系统检测 ----------
if command -v pacman >/dev/null 2>&1; then
  os="linux"
  arch=$(uname -m)
  package_suffix=".pkg.tar.zst"
  package_install="pacman -U --noconfirm"
elif command -v dpkg >/dev/null 2>&1; then
  os="linux"
  arch=$(dpkg --print-architecture)
  package_suffix=".deb"
  package_install="dpkg -i"
elif command -v dnf >/dev/null 2>&1; then
  os="linux"
  arch=$(uname -m)
  package_suffix=".rpm"
  package_install="dnf install -y"
elif command -v rpm >/dev/null 2>&1; then
  os="linux"
  arch=$(uname -m)
  package_suffix=".rpm"
  package_install="rpm -i"
else
  echo "Unsupported package manager"
  exit 1
fi

# ---------- 架构映射（关键） ----------
case "$arch" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
esac

# ---------- 获取版本 ----------
if [ -z "$download_version" ]; then
  API_URL="https://api.github.com/repos/Xiaokailnol/mihomo-template/releases/latest"
  if [ -n "$GITHUB_TOKEN" ]; then
    latest_release=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$API_URL")
  else
    latest_release=$(curl -s "$API_URL")
  fi

  download_version=$(echo "$latest_release" \
    | grep '"tag_name"' \
    | head -n 1 \
    | sed -E 's/.*"v?([^"]+)".*/\1/')
fi

# ---------- 生成包名 ----------
package_name="mihomo-${os}-${download_version}-${arch}${package_suffix}"

package_url="https://github.com/Xiaokailnol/mihomo-template/releases/download/v${download_version}/${package_name}"

echo "Downloading: $package_url"

if [ -n "$GITHUB_TOKEN" ]; then
  curl --fail -Lo "$package_name" -H "Authorization: token ${GITHUB_TOKEN}" "$package_url"
else
  curl --fail -Lo "$package_name" "$package_url"
fi

[ $? -ne 0 ] && exit 1

# ---------- 安装 ----------
command -v sudo >/dev/null 2>&1 && package_install="sudo $package_install"

sh -c "$package_install \"$package_name\""

rm -f "$package_name"
