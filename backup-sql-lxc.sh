#!/bin/bash
backup="/var/backup"
pass=`grep PASS /usr/local/sbin/mysqldump_backup.rb | head -1 | cut -d\' -f2`;
mount $backup
banco = "$1";
if [ -z "$banco" ];
    then
        echo "============================================"
        echo "= Parametro do banco nulo, informe o banco ="
        echo "============================================"
        exit;
fi
if [ -z `find $backup -iname "$banco.sql.gz"` > /dev/null 2>&1 ];
    then
        echo "================================"
        echo "= Não existe backup deste banco="
        echo "================================"
        umount /var/backup
        exit;
fi
if [ -z `find /var/lib/mysql/ -iname "$banco"` > /dev/null 2>&1 ];
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
for i in `find $backup -iname "$banco.sql.gz" | sort | cut -d'/' -f5`; 
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
zcat /var/backup/mysqldump/$data_solicitada/$banco.sql.gz > /var/backup/$banco.sql;
echo "------------->Restaurando..."
mysql -p$pass $banco < /var/backup/$banco.sql;
echo "------------->Desmontando partição de backup..."
rm /var/backup/$banco.sql
umount $backup
echo "------------->Backup finalizado!"
exit;
