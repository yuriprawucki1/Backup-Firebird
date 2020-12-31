# Backup Firebird Script
#
## Programando o backup para todo dia as 20hrs com notificação por e-mail
#### crontab -e
#### 00 20 * * * /root/bin/backup_firebird.sh | mail -A no-reply -s "SRV-FIREBIRD - Backup Firebird Databases" meu@email.com.br
#
## Componentes necessários:
#### GDRIVE: https://github.com/prasmussen/gdrive
#### MAILX:
##### --> Centos: yum install -y mailx
##### --> Debian: apt install bsd-mailx
#
##### vim /etc/mail.rc
