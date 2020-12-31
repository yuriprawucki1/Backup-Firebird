#!/bin/bash

# Get Firebird username and password
FB_USER="SYSDBA"
FB_PASS="masterkey"

# Get password of backup file compress
PSWD_ZIP='MyPassword'

# Get today date
TODAY="$(date +"%d_%m_%Y")"

# Get todat date on GDRIVE
TODAY_GDRIVE="$(date +"%Y-%m-%d")"

# Get date 10 days ago on GDRIVE
TODAY_GDRIVE_OLD="$(date -d "-11 days" +'%Y-%m-%d')"

# Get database directory
DB_SOURCES="/srv/FirebirdDB"

# Get backup directory
BACKUP_PATH="/mnt/BKP"

echo ' '
echo -n 'Processo de backup iniciado em: ' && date +%d/%m/%Y' - as '%H:%M
echo ' '
echo ' '

# Remove old backup files from disk
find $BACKUP_PATH -type f -ctime +18 -exec rm {} \;

# Remove old backup files from GDRIVE
echo -n 'Excluindo pasta antiga de backup no Google Drive'
/sbin/gdrive list --query "createdTime < '${TODAY_GDRIVE_OLD}' and mimeType = 'application/vnd.google-apps.folder'" | awk 'FNR == 2 {print $1}' > /root/fb_gdrive_old.txt
FB_GDRIVE_OLD=$(cat /root/fb_gdrive_old.txt)
/sbin/gdrive delete -r $FB_GDRIVE_OLD
echo ' '

for DB_SOURCE in $DB_SOURCES; do
    mkdir -p ${BACKUP_PATH}/${TODAY}

    for DATABASE_PATH in 'find ${DB_SOURCE} -name "*.fdb"'; do
	DATABASE_BACKUP=${DATABASE_PATH##*/}

	echo "Backup ${DATABASE_BACKUP}"

	if gbak -g -b -z -v -t -user ${FB_USER} -password ${FB_PASS} ${DATABASE_PATH} ${BACKUP_PATH}/${TODAY}/${DATABASE_BACKUP}.fbk.tmp &>> "${BACKUP_PATH}/${TODAY}/${DATABASE_BACKUP}.fbk.log"; then
    	    mv ${BACKUP_PATH}/${TODAY}/${DATABASE_BACKUP}.fbk.tmp ${BACKUP_PATH}/${TODAY}/${DATABASE_BACKUP}.fbk
    	    for FILE in $(ls ${BACKUP_PATH}/${TODAY}/*.fbk); do
        	7za a -r -tzip -bso0 -bsp0 -sdel -p$PSWD_ZIP ${FILE}.zip ${FILE} && md5sum ${FILE}.zip &>> ${BACKUP_PATH}/${TODAY}/checksums.md5
    	    done
    	    echo " - Arquivo de dump gerado com sucesso."
    	else
    	    echo " - Erro ao exportar o banco de dados."
    	fi
    done
done

echo ' '
echo -n 'Processo de upload do backup para o Google Drive iniciado em: ' && date +%d/%m/%Y' - as '%H:%M
echo ' '

# Upload folder from backup to GDRIVE
/sbin/gdrive upload --recursive ${BACKUP_PATH}/${TODAY}

echo ' '
echo -n 'Processo de upload do backup para o Google Drive finalizado com sucesso em: ' && date +%d/%m/%Y' - as '%H:%M
echo ' '

# Remove old backup folders from disk
find $BACKUP_PATH -empty -type d -exec rmdir {} \; 2> /dev/null

echo ' '
echo -n 'Processo de backup finalizado com sucesso em: ' && date +%d/%m/%Y' - as '%H:%M
echo ' '
