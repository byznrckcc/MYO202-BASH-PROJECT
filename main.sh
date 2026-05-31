#!/bin/bash
# BEYZANUR ÇAKICI
# 2420191032
# 1. Docker Temelleri: https://www.btkakademi.gov.tr/portal/certificate/validate?certificateId=PVghMZyA0O
# 2. Siber Güvenlikte Linux İşletim Sistemleri: https://www.btkakademi.gov.tr/portal/certificate/validate?certificateId=8jmhLrxDxo
# 3. Linux Bash Script Eğitimi: https://credsverse.com/credentials/4f5ec6d3-70ca-48cd-80cd-ea302c18f1d8

# log dosyasi adi
cikti="report.log"

# ilk satira direkt iso saatini yazdiriyorum
date --iso-8601=seconds > "$cikti"

# isletim sistemi tespiti yapiyoruz git bash uyumu icin
if [[ "$OSTYPE" == *"msys"* || "$OSTYPE" == *"cygwin"* || "$(uname)" == *"MINGW"* ]]; then
    echo "--- Windows Donanim Detaylari ---" >> "$cikti"
    wmic cpu get name | grep -v "Name" | grep . >> "$cikti" 2>&1
    wmic computersystem get totalphysicalmemory | grep -v "Total" | grep . >> "$cikti" 2>&1
    wmic csproduct get uuid | grep -v "UUID" | grep . >> "$cikti" 2>&1
    wmic diskdrive get model,serialnumber,size | grep -v "Model" | grep . >> "$cikti" 2>&1
    getmac >> "$cikti" 2>&1

elif [[ "$OSTYPE" == *"darwin"* || "$(uname)" == *"Darwin"* ]]; then
    echo "--- MacOS Donanim Detaylari ---" >> "$cikti"
    system_profiler SPHardwareDataType | grep -E "Processor Name|Memory|Hardware UUID" >> "$cikti"
    system_profiler SPStorageDataType | grep "Size" >> "$cikti"
    ifconfig | grep ether >> "$cikti"

else
    echo "--- Linux Donanim Detaylari ---" >> "$cikti"
    lscpu | grep "Model name" | awk -F: '{print $2}' | xargs >> "$cikti"
    free -h | grep "Mem:" | awk '{print "RAM Kapasite: " $2}' >> "$cikti"
    cat /sys/class/dmi/id/product_uuid >> "$cikti" 2>/dev/null || echo "UUID erisimi yok" >> "$cikti"
    lsblk -d -o NAME,MODEL,SERIAL,SIZE | grep -v "NAME" >> "$cikti"
    ip link | grep ether | awk '{print "MAC: " $2}' >> "$cikti"
fi

echo "Sistem tarama betigi baslatildi, lutfen bekleyin..."
read -sp "Lutfen parolanizi giriniz: " PAROLA
echo ""

# surec listesine (process list) sifre sizmasin diye pipeline kullandim
echo "$PAROLA" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o report.log.gpg "$cikti"

# gpg dosyasi olustuysa ham logu siliyoruz
if [ -f "report.log.gpg" ]; then
    rm -f "$cikti"
    echo "[+] Islem tamamlandi. report.log.gpg olusturuldu."
else
    echo "[-] Bir hata olustu."
    exit 1
fi

# bellek uzerindeki parolanin izini siliyoruz
unset PAROLA
