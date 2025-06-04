
#!/bin/bash

REMOTE_HOST="10.0.22.12" # Remote IP
REMOTE_USER="kasutaja" # Remote kasutaja kellega siseneb
DB_NAME="kasutajatugi" # DB nimi
DB_USER="kasutajatugi" # DB kasutaja
DB_PASS="parool" # DB parool
LOCAL_WEB_DIR="/var/www/kasutajatugi" # Kaust millest tehakse koopia localis
BACKUP_DIR="./backups" # Salvestab backups kausta, alates sellest kaustast kus oleme
DATE=$(date +"%Y-%m-%d_%H-%M") # Aeg
TMP_DIR="$HOME/backup_temp_$DATE" # Ajutine kaust
BACKUP_FILE="varukoopia_${DATE}.tar.gz" # Lisab aja failile

mkdir -p "$BACKUP_DIR" # Loob kausta backups
mkdir -p "$TMP_DIR" # Loob kausta backup_temp_aeg

# SSHga serverisse et teha mysql dump ja kirjutada see TMP_DIR väärtuse kausta
ssh ${REMOTE_USER}@${REMOTE_HOST} "mysqldump -u ${DB_USER} -p'${DB_PASS}' ${DB_NAME}" > "$TMP_DIR/db_dump.sql"
if [ $? -ne 0 ]; then
  echo "Andmebaasi dump ebaõnnestus"
  exit 1
fi

# Kui on lokaalne web dir väärtus siis pakime failid kokku tmp_dir kausta
if [ -d "$LOCAL_WEB_DIR" ]; then
  tar -czf "$TMP_DIR/website.tar.gz" -C "$(dirname $LOCAL_WEB_DIR)" "$(basename $LOCAL_WEB_DIR)"
else
  echo "Veebikaust $LOCAL_WEB_DIR ei leitud"
  exit 1
fi

tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" -C "$TMP_DIR" .

# Kustutame kausta ja selle sisu
rm -rf "$TMP_DIR"

# Otsime backup_dir väärtusest vanemad kui 7 päeva ja kustutame
find "${BACKUP_DIR}" -type f -name "varukoopia_*.tar.gz" -mtime +7 -exec rm {} \;

# Logi
echo "Varukoopia loodud: ${BACKUP_DIR}/${BACKUP_FILE}"
