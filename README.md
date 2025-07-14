
# MySQL RAM Disk Setup Script

Bu bash script, MariaDB/MySQL sunucusunda geçici tabloların RAM üzerinde tutulması için otomatik yapılandırma yapar.
* Önerilen Ram DDR4 ve Üstü
* 
## Özellikler

- `/etc/systemd/system/mariadb.service.d/override.conf` dosyasını kontrol eder, yoksa oluşturur ve `ProtectHome=false` ayarını ekler.
- `/home/mysqltmp` dizinini oluşturur ve uygun izinleri ayarlar.
- `/etc/my.cnf` dosyasında `tmpdir` ayarını kontrol eder ve gerekirse ekler.
- Sistemdeki toplam RAM miktarına göre önerilen tmpfs boyutunu gösterir.
- Kullanıcıdan önerilen tmpfs boyutunu kabul etmesini ya da elle boyut girmesini ister.
- `/home/mysqltmp` dizinini tmpfs (RAM disk) olarak mount eder.
- `/etc/fstab` dosyasına kalıcı mount satırı ekler.

## Kullanım

1. Script dosyasını indir veya kopyala:

   ```bash
   wget https://github.com/OmerAti/whm-cpanel-mysqltmp/raw/main/mysql_ram_setup.sh
