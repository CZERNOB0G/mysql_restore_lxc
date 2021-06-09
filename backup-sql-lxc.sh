#!/bin/bash
backup="/var/backup"
pass=`grep PASS /usr/local/sbin/mysqldump_backup.rb | head -1 | cut -d\' -f2`;
mount $backup
#$1 = banco
if [ -z `find $backup -iname "$1.sql.gz"` > /dev/null 2>&1 ];
    then
        echo "================================"
        echo "= Não existe backup deste banco="
        echo "================================"
        umount /var/backup
        exit;
fi
corrige_unicode_banco=`echo "$1" | tr -s "[:punct:]" "*"` > /dev/null 2>&1;
if [ -z `find /var/lib/lxc/mysql/ -iname "$corrige_unicode_banco"` > /dev/null 2>&1 ];
    then
        echo "========================="
        echo "= Esse banco não existe ="
        echo "========================="
        umount /var/backup
        exit;
fi
echo "========================================"
echo "= Escolha a data que deseja restaurar: ="
echo "========================================"
data_find=()
for i in `find $backup -iname "$1.sql.gz" | sort | cut -d'/' -f5`; 
    do 
    	let inc++;
    	data_find[$inc]=$i;
    	echo "$inc: $i";
done
echo "========================================"
read id_data_solicitada
if [ -z ${data_find[$id_data_solicitada]} ];
    then
        echo "=================="
        echo "= Opção inválida ="
        echo "=================="
        umount /var/backup
        exit;
fi
data_solicitada="${data_find[$id_data_solicitada]}"
echo "------------->Descompactando o backup: $data_solicitada..."
zcat /var/backup/mysqldump/$data_solicitada/$1.sql.gz > /var/backup/$1.sql;
conteiner=`find /var/lib/lxc/mysql -iname "$corrige_unicode_banco" | awk -F'/' '{print $6}' | head -n1`;
echo "------------->Definindo conteiner: $conteiner";
echo "------------->Restaurando..."
lxc-attach -n $conteiner -- mysql -p$pass $1 < /var/backup/$1.sql;
echo "------------->Desmontando partição de backup..."
rm /var/backup/$1.sql
umount $backup
echo "------------->Backup finalizado!"
exit;
