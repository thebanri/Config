# Go
set -gx GOPATH $HOME/go
fish_add_path -g $GOPATH/bin $HOME/.local/bin

# zoxide: `z` ile dizin atla, `zi` ile fzf üzerinden seç
if status is-interactive; and type -q zoxide
    zoxide init fish | source
end
