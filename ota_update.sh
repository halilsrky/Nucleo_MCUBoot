#!/bin/bash

# ================= Ayarlar =================
PORT="/dev/ttyACM1"
BAUD="115200"
BIN_FILE="build_app/zephyr/zephyr.signed.bin"
CONN="dev=$PORT,baud=$BAUD"
# ===========================================

echo -e "\n🚀 [ADIM 1] Firmware yükleniyor ($BIN_FILE)..."
mcumgr --conntype serial --connstring $CONN image upload $BIN_FILE

# Yükleme başarısız olursa scripti durdur
if [ $? -ne 0 ]; then
    echo "❌ Hata: Yükleme işlemi başarısız oldu!"
    exit 1
fi

echo -e "\n🔍 [ADIM 2] İmajlar listeleniyor ve yeni Hash aranıyor..."
# mcumgr çıktısını okuyup sadece 'slot=1' altındaki 'hash:' satırını çeken filtre
HASH=$(mcumgr --conntype serial --connstring $CONN image list | awk '/slot=1/{flag=1} flag && /hash:/{print $2; exit}')

# Hash boş döndüyse scripti durdur
if [ -z "$HASH" ]; then
    echo "❌ Hata: Slot 1'de yeni bir imaj veya Hash değeri bulunamadı!"
    exit 1
fi

echo "✅ Bulunan Hash: $HASH"

echo -e "\n⚙️  [ADIM 3] İmaj test (Pending) olarak işaretleniyor..."
mcumgr --conntype serial --connstring $CONN image test $HASH

if [ $? -ne 0 ]; then
    echo "❌ Hata: İmaj test için işaretlenemedi!"
    exit 1
fi

echo -e "\n🔄 [ADIM 4] Kart yeniden başlatılıyor (Swap işlemi tetikleniyor)..."
mcumgr --conntype serial --connstring $CONN reset

echo -e "\n⏳ Swap işleminin tamamlanması bekleniyor..."

# === 10 Saniyelik Loading Bar Başlangıcı ===
for i in {1..10}; do
    # Bar ve boşluk kısımlarını hesapla
    BAR=$(printf "%-${i}s" "" | tr ' ' '#')
    SPACE=$(printf "%-$((10-i))s" "")
    
    # \r ile satırı temizleyip üzerine yazar (animasyon efekti)
    echo -ne "\r[${BAR}${SPACE}] %$((i * 10)) "
    sleep 1
done
echo -e "\n" # Bar dolduktan sonra alt satıra geç
# === Loading Bar Bitişi ===

echo -e "📊 [ADIM 5] Güncel İmaj Durumu Kontrol Ediliyor..."
mcumgr --conntype serial --connstring $CONN image list

echo -e "\n🎉 BİTTİ! Kart şu an güncellendi."