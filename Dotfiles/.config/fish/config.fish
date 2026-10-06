source /usr/share/cachyos-fish-config/cachyos-config.fish

# Kendi fonksiyonlarım: https://github.com/thebanri/scripts (install.sh --only scripts)
test -d ~/scripts; and set -p fish_function_path ~/scripts

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
