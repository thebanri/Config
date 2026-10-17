# zapret'i açar, açılışta da başlar.
function zapret-on --description 'zapret DPI atlatmayı aç'
    sudo systemctl enable --now zapret.service
end
