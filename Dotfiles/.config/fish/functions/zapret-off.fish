# zapret'i kapatır, açılışta da başlamaz. Tekrar açmak için: zapret-on
function zapret-off --description 'zapret DPI atlatmayı kapat'
    sudo systemctl disable --now zapret.service
end
