# Nucleo MCUboot Projesi

Bu proje, NUCLEO-G431KB kartı üzerinde MCUboot ve Zephyr OS kullanarak Seri Port üzerinden (OTA/SMP) güncelleme işlemlerini gerçekleştirmek için derleme, flaşlama ve test komutlarını içermektedir.

## 1. MCUboot İşlemleri

### MCUboot'u Derleme (Build)
MCUboot çekirdeğini kendi konfigürasyon ve overlay dosyalarımız (`custom_mcuboot.conf`, `mcuboot_nucleo.overlay`) ile derlemek için:

```bash
west build -b nucleo_g431kb -d /home/halil/myZephyrProjects/nucleo_mcuboot/build_mcuboot /home/halil/zephyrproject/bootloader/mcuboot/boot/zephyr -- -DDTC_OVERLAY_FILE=/home/halil/myZephyrProjects/nucleo_mcuboot/mcuboot_nucleo.overlay -DEXTRA_CONF_FILE=/home/halil/myZephyrProjects/nucleo_mcuboot/custom_mcuboot.conf
```

### MCUboot'u Flaşlama (Flash)
Python sanal ortamınızı etkinleştirdikten sonra derlenen bootloader'ı cihaza yazdırmak için kullanılır:

```bash
source ~/zephyrproject/.venv/bin/activate
west flash -d build_mcuboot --hex-file build_mcuboot/zephyr/zephyr.hex -r openocd
```

---

## 2. Ana Uygulama (APP) İşlemleri

### Uygulamayı Derleme
Ana Zephyr uygulamasını derlemek için:

```bash
west build -b nucleo_g431kb . -d build_app
```

### Uygulamayı İmzalama (Sign & Version)
MCUboot'un boot edebilmesi için derlenen uygulamayı, imgtool kullanarak `signing.pem` ile imzalamamız ve bir versiyon vermemiz gerekir *(Örnek versiyon: 1.0.2)*:

```bash
west sign -t imgtool -d build_app -p ~/zephyrproject/bootloader/mcuboot/scripts/imgtool.py -- --key keys/signing.pem --slot-size 0xA000 --align 8 --version 1.0.2
```

### İlk Sürümü Flaşlama (Kablo/ST-Link Üzerinden)
İlk imaj cihazda henüz çalışmadığı için OTA yapmadan ilk versiyonu elle cihaza flaşlamanız gerekebilir:

```bash
west flash -d build_app --hex-file build_app/zephyr/zephyr.signed.hex -r openocd
```

---

## 3. OTA (SMP) ile Seri Port Üzerinden Cihazı Güncelleme

Cihazda mevcut bir uygulama çalışırken, yeni imajı (.bin) seri haberleşme üzerinden (SMP protokolü ile) göndermek için `mcumgr` komutları kullanılır. *(Not: `ttyACM1` değişiklik gösterebilir, cihaz portunu dmesg ile kontrol ediniz)*

### Yeni İmajı Yükleme (Upload)
```bash
mcumgr --conntype serial --connstring dev=/dev/ttyACM1,baud=115200 image upload build_app/zephyr/zephyr.signed.bin
```

### İmajları Listeleme (List)
Karta yüklenen imajları bulmak ve Slot-1'de "Pending" bekleyen imajın HASH değerini öğrenmek için:
```bash
mcumgr --conntype serial --connstring dev=/dev/ttyACM1,baud=115200 image list
```

### İmajı Test Olarak İşaretleme (Test)
Kopyaladığınız yeni hash değerini buraya girerek bir sonraki yeniden başlatmada imajın Bootloader tarafından boot edilmesini emredin:
```bash
mcumgr --conntype serial --connstring dev=/dev/ttyACM1,baud=115200 image test <KOPYALANAN_HASH_DEGERI>
```

### İşaretleme Sonrası Cihazı Yeniden Başlatma (Reset)
Kartı sıfırlayıp bootloader'a giriş yapmak için:
```bash
mcumgr --conntype serial --connstring dev=/dev/ttyACM1,baud=115200 reset
```
