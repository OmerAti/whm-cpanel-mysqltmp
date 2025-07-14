#!/bin/bash

OVERRIDE_FILE="/etc/systemd/system/mariadb.service.d/override.conf"
if [ ! -f "$OVERRIDE_FILE" ]; then
  echo "$OVERRIDE_FILE bulunamadi. Olusturulsun mu? (e/h)"
  read -r cevap
  if [[ "$cevap" =~ ^[Ee]$ ]]; then
    mkdir -p "$(dirname "$OVERRIDE_FILE")"
    cat > "$OVERRIDE_FILE" << EOF
[Service]
ProtectHome=false
EOF
    echo "$OVERRIDE_FILE olusturuldu."
    systemctl daemon-reload
    echo "systemctl daemon-reload calistirildi."
  else
    echo "Atlandi."
  fi
else
  grep -q "ProtectHome=false" "$OVERRIDE_FILE" || {
    echo "$OVERRIDE_FILE var, ama ProtectHome=false yok. Eklemek ister misiniz? (e/h)"
    read -r cevap
    if [[ "$cevap" =~ ^[Ee]$ ]]; then
      echo -e "\nProtectHome=false" >> "$OVERRIDE_FILE"
      echo "ProtectHome=false eklendi."
      systemctl daemon-reload
      echo "systemctl daemon-reload calistirildi."
    else
      echo "Atlandi."
    fi
  }
fi

if [ ! -d /home/mysqltmp ]; then
  mkdir /home/mysqltmp
  echo "/home/mysqltmp olusturuldu."
else
  echo "/home/mysqltmp zaten var."
fi

chown mysql:mysql /home/mysqltmp
echo "/home/mysqltmp mysql:mysql olarak ayarlandi."

MYCNF="/etc/my.cnf"
if grep -q "^tmpdir\s*=" "$MYCNF"; then
  echo "$MYCNF icinde tmpdir zaten ayarli."
else
  echo "$MYCNF icinde tmpdir ayari bulunamadi. Eklemek ister misiniz? (e/h)"
  read -r cevap
  if [[ "$cevap" =~ ^[Ee]$ ]]; then
    echo -e "\ntmpdir = /home/mysqltmp" >> "$MYCNF"
    echo "tmpdir = /home/mysqltmp $MYCNF dosyasina eklendi."
  else
    echo "Atlandi."
  fi
fi

TOTAL_RAM_MB=$(free -m | awk '/Mem:/ {print $2}')
echo ""
echo "Toplam RAM miktariniz: ${TOTAL_RAM_MB} MB"

if (( TOTAL_RAM_MB >= 32000 )); then
  RECOMMENDED_SIZE="4G"
elif (( TOTAL_RAM_MB >= 16000 )); then
  RECOMMENDED_SIZE="3G"
elif (( TOTAL_RAM_MB >= 8000 )); then
  RECOMMENDED_SIZE="2G"
elif (( TOTAL_RAM_MB >= 4000 )); then
  RECOMMENDED_SIZE="1G"
else
  RECOMMENDED_SIZE="512M"
fi

echo "Sistem RAM miktariniza gore tmpfs icin onerilen boyut: $RECOMMENDED_SIZE"

echo "Onerilen boyutu eklemek ister misiniz yoksa elle girmek ister misiniz? (onerilen/elle)"
read -r secim

case "$secim" in
  onerilen|Onerilen|o|O)
    SIZE_TO_USE=$RECOMMENDED_SIZE
    ;;
  elle|Elle|e|E)
    echo "Lutfen tmpfs icin boyutu giriniz (ornek: 2G, 512M):"
    read -r elle_boyut
    SIZE_TO_USE=$elle_boyut
    ;;
  *)
    echo "Gecersiz secim, onerilen boyut kullanilacak."
    SIZE_TO_USE=$RECOMMENDED_SIZE
    ;;
esac

MOUNT_POINT="/home/mysqltmp"
MOUNTED=$(mount | grep "on $MOUNT_POINT type tmpfs")

if [ -z "$MOUNTED" ]; then
  echo "$MOUNT_POINT tmpfs olarak mount edilmemis. Simdi mount edilsin mi? (e/h)"
  read -r cevap
  if [[ "$cevap" =~ ^[Ee]$ ]]; then
    mount -t tmpfs -o size=$SIZE_TO_USE tmpfs "$MOUNT_POINT"
    echo "$MOUNT_POINT tmpfs olarak mount edildi."
  else
    echo "Mount islemi atlandi."
  fi
else
  echo "$MOUNT_POINT zaten tmpfs olarak mount edilmis."
fi

FSTAB_LINE="tmpfs $MOUNT_POINT tmpfs defaults,size=$SIZE_TO_USE 0 0"
if grep -qF "$FSTAB_LINE" /etc/fstab; then
  echo "/etc/fstab dosyasinda kalici mount satiri zaten var."
else
  echo "/etc/fstab dosyasina kalici mount satiri eklenmeli. Eklemek ister misiniz? (e/h)"
  read -r cevap
  if [[ "$cevap" =~ ^[Ee]$ ]]; then
    echo "$FSTAB_LINE" >> /etc/fstab
    echo "Kalici mount satiri /etc/fstab dosyasina eklendi."
  else
    echo "Atlandi."
  fi
fi

echo "Islem tamamlandi."
