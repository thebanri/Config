#!/bin/bash
# Dotfiles/ altındaki dosyaların sistemdeki güncel hâllerini repoya çeker.
# Yeni bir dosya eklemek için önce Dotfiles/ altına aynı yolla kopyala, sonra bu script onu takip eder.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/Dotfiles"
changed=0
while IFS= read -r -d '' rel; do
    rel=${rel#./}
    if [[ ! -e $HOME/$rel ]]; then
        echo "  ! sistemde yok: ~/$rel"
    elif ! cmp -s "$HOME/$rel" "$rel"; then
        cp "$HOME/$rel" "$rel"
        echo "  ✓ güncellendi: ~/$rel"
        changed=$((changed + 1))
    fi
done < <(find . -type f -print0 | sort -z)

# Dotfiles dışındaki sistem ayarları: sistemdeki yol -> repodaki yol
while read -r sys rel; do
    if [[ ! -e $sys ]]; then
        echo "  ! sistemde yok: $sys"
    elif ! cmp -s "$sys" "../$rel"; then
        cp "$sys" "../$rel"
        echo "  ✓ güncellendi: $sys"
        changed=$((changed + 1))
    fi
done <<'EOF'
/opt/zapret/config Zapret/config
/opt/zapret/ipset/zapret-hosts-user.txt Zapret/zapret-hosts-user.txt
/etc/systemd/resolved.conf.d/dot.conf DNS/cloudflare.conf
EOF
echo "$changed dosya güncellendi. Kontrol: git diff"
