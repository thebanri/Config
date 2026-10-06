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
echo "$changed dosya güncellendi. Kontrol: git diff"
