#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/dr-hands-image.log /dev/ttyS0) 2>&1
report() { echo "DR-HANDS-IMAGE-$1"; }
trap 'report FAILED; sleep 900; systemctl poweroff' ERR

root=$(cd "$(dirname "$0")/.." && pwd)
files=$root/image/files
. "$root/site.env"
mise_version=2026.10.20
mise_sha256=81047ebf136016297f4515132265c3e5fc052f2c4090130a4e8d68fd64b96b57
herdr_version=0.9.5
herdr_sha256=17d7536f2da50859523680ef279dffcac8e4a235f4e46fe8da6c2ec44141897c
tailscale_version=1.94.2
export DEBIAN_FRONTEND=noninteractive
echo 'DPkg::Lock::Timeout "600";' > /etc/apt/apt.conf.d/90dr-hands-lock

apt-get update
apt-get -y full-upgrade
apt-get install -y --no-install-recommends \
	build-essential git curl ca-certificates jq ripgrep fd-find less nano procps unzip xz-utils pkg-config \
	nftables squid openssh-server
for stack in $DR_HANDS_STACKS; do
	if [ -f "$root/stacks/$stack/packages" ]; then
		xargs apt-get install -y --no-install-recommends < "$root/stacks/$stack/packages"
	fi
done
apt-get purge -y unattended-upgrades || true

install -m 0644 "$files/tailscale-archive-keyring.gpg" /usr/share/keyrings/tailscale-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian trixie main" \
	> /etc/apt/sources.list.d/tailscale.list
apt-get update
apt-get install -y "tailscale=$tailscale_version"
apt-mark hold tailscale

curl -fsSLo /usr/local/bin/mise "https://github.com/jdx/mise/releases/download/v$mise_version/mise-v$mise_version-linux-arm64"
echo "$mise_sha256  /usr/local/bin/mise" | sha256sum -c
chmod 0755 /usr/local/bin/mise

curl -fsSLo /usr/local/bin/herdr "https://github.com/herdrdev/herdr/releases/download/v$herdr_version/herdr-linux-aarch64"
echo "$herdr_sha256  /usr/local/bin/herdr" | sha256sum -c
chmod 0755 /usr/local/bin/herdr

useradd --create-home --shell /bin/bash agent
install -d -m 0700 -o agent -g agent /home/agent/.ssh /home/agent/.config /home/agent/.config/mise /home/agent/.config/mise/conf.d /home/agent/.pi /home/agent/.pi/agent /home/agent/work
install -m 0600 -o agent -g agent "$files/mise.toml" /home/agent/.config/mise/config.toml
install -m 0600 -o agent -g agent "$files/pi-settings.json" /home/agent/.pi/agent/settings.json
install -m 0644 -o agent -g agent "$files/AGENTS.md" /home/agent/.pi/agent/AGENTS.md
for stack in $DR_HANDS_STACKS; do
	if [ -f "$root/stacks/$stack/mise.toml" ]; then
		install -m 0600 -o agent -g agent "$root/stacks/$stack/mise.toml" "/home/agent/.config/mise/conf.d/$stack.toml"
	fi
done
sed "s/@BROKER_HOST@/$DR_HANDS_BROKER_HOST/" "$files/profile.sh" > /etc/profile.d/dr-hands.sh
chmod 0644 /etc/profile.d/dr-hands.sh
echo '. /etc/profile.d/dr-hands.sh' >> /home/agent/.bashrc

runuser -u agent -- env -i HOME=/home/agent USER=agent \
	PATH=/home/agent/.local/share/mise/shims:/usr/local/bin:/usr/bin:/bin \
	bash -c 'cd ~ && mise install --yes && meridian setup --client pi'
test -f /home/agent/.pi/agent/extensions/meridian/index.ts

for list in "$files/allowed-hosts" $(for stack in $DR_HANDS_STACKS; do echo "$root/stacks/$stack/hosts"; done); do
	if [ -f "$list" ]; then cat "$list"; fi
done | sort -u > /etc/squid/allowed-hosts
chmod 0644 /etc/squid/allowed-hosts
install -m 0644 "$files/squid.conf" /etc/squid/squid.conf
squid -k parse
sed "s/@BROKER_IP@/$DR_HANDS_BROKER_IP/" "$files/nftables.conf" > /etc/nftables.conf
chmod 0644 /etc/nftables.conf
nft -c -f /etc/nftables.conf
install -m 0644 "$files/sshd.conf" /etc/ssh/sshd_config.d/10-dr-hands.conf
install -m 0644 "$files/dr-hands-expire.service" /etc/systemd/system/dr-hands-expire.service
install -m 0644 "$files/dr-hands-expire.timer" /etc/systemd/system/dr-hands-expire.timer
echo "$DR_HANDS_BROKER_IP $DR_HANDS_BROKER_HOST" >> /etc/hosts
if [ -f /etc/cloud/templates/hosts.debian.tmpl ]; then
	echo "$DR_HANDS_BROKER_IP $DR_HANDS_BROKER_HOST" >> /etc/cloud/templates/hosts.debian.tmpl
fi
systemctl enable nftables squid tailscaled ssh dr-hands-expire.timer

rm -f /etc/ssh/ssh_host_* /home/agent/.bash_history /root/.bash_history
apt-get clean
cloud-init clean --logs
report OK
sleep 45
systemctl poweroff
