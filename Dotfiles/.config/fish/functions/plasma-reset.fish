# Görev çubuğu önizlemeleri kaybolursa (kpipewire format hatası) paneli yeniden başlatır.
# Açık pencerelere dokunmaz, panel birkaç saniye kaybolup geri gelir.
function plasma-reset --description 'Plasma panelini yeniden başlat'
    systemctl --user restart plasma-plasmashell.service
end
