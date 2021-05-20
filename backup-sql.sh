#!/bin/bash
backup="/var/backup"
pass=`grep PASS /usr/local/sbin/mysqldump_backup.rb | head -1 | cut -d\' -f2`;
#Verifica se a partição está montada
if mount | grep $backup > /dev/null;
    then
        echo "============================================================================"
        echo "= A partição de backup está montada, deseja prosseguir mesmo assim? (S/N): ="
        echo "============================================================================"
        read confirmacao
        #Se a resposta for diferente s e n, ele faz o backup.
        while [ ${confirmacao^} != 'S' -a ${confirmacao^} != 'N' ];
        do
            echo "=================================================="
            echo "= Opção inválida, deseja tentar novamente? (S/N) ="
            echo "=================================================="
            read confirmacao
            if [ ${confirmacao^} != 'S' ];
                then
	           	echo "============================"
               	    	echo "= Abortando a restauração! ="
	                echo "============================"
                    	umount $backup
                    	umount $baktodo
	                exit;
		else
			echo "============================================================================"
			echo "= A partição de backup está montada, deseja prosseguir mesmo assim? (S/N): ="
			echo "============================================================================"
			read confirmacao
	    fi
        done
        #Se a resposta for n/N ele desmona a partição e para o script.
        if [ ${confirmacao^} != 'S' ];
            then
		echo "============================"
                echo "= Abortando a restauração! ="
		echo "============================"
                exit;
        fi
fi
mount $backup
echo "========================================="
echo "= Informe o banco que deseja restaurar: ="
echo "========================================="
read banco
#Se o banco não existe ele entra no looping até que informe um que exista.
while [ -z `find $backup -iname "$banco.sql.gz"` > /dev/null 2>&1 ];
    do
        echo "============================================================="
        echo "= Não existe backup deste banco, deseja tentar outro? (S/N) ="
        echo "============================================================="
        read confirmacao
        if [ ${confirmacao^} != 'S' ];
            then
                #Se digitar n/N ele desmonta o backup e para o script.
	        echo "============================"
               	echo "= Abortando a restauração! ="
	        echo "============================"
               	umount $backup
		exit;
            else
	        echo "========================================="
                echo "= Informe novamente o banco do banco: ="
                echo "========================================="
                read banco
	fi
done
corrige_unicode_banco=`echo "$banco" | tr -s "[:punct:]" "*"` > /dev/null 2>&1;
while [ -z `find /var/lib/lxc/mysql/ -iname "$corrige_unicode_banco"` > /dev/null 2>&1 ];
    do
        echo "====================================================="
        echo "= Esse banco não existe, deseja tentar outro? (S/N) ="
        echo "====================================================="
        read confirmacao
        if [ ${confirmacao^} != 'S' ];
            then
                #Se digitar n/N ele desmonta o backup e para o script.
	        echo "============================"
               	echo "= Abortando a restauração! ="
	        echo "============================"
                umount $backup
		exit;
            else
	        echo "======================================="
                echo "= Informe novamente o banco do banco: ="
                echo "======================================="
                read banco
	fi
done
#Informa as datas existentes para backup e cria uma array para selecionar a que você deseja..
echo "========================================"
echo "= Escolha a data que deseja restaurar: ="
echo "========================================"
data_find=()
#Ele lista enquanto ele achar uma data referente ao banco e corta o resultado para exibir somente a data.
for i in `find $backup -iname "$banco.sql.gz" | sort | cut -d'/' -f5`; 
    do 
    	let inc++;
    	data_find[$inc]=$i;
    	echo "$inc: $i";
done
echo "========================================"
read id_data_solicitada
#Enquano informar um numero fora do escopo da array ele entra em um looping até que informe um número existente.
while [ -z ${data_find[$id_data_solicitada]} ];
    do
        echo "=================================================="
        echo "= Opção inválida, deseja tentar novamente? (S/N) ="
        echo "=================================================="
        read confirmacao
        if [ ${confirmacao^} != 'S' ];
            then
                #Se digitar n/N ele desmonta o backup e para o script.
	        echo "============================"
               	echo "= Abortando a restauração! ="
	        echo "============================"
                umount $backup
	        exit;
            else
                echo "=================================================="
                echo "= Escolha novamente a data que deseja restaurar: ="
                echo "=================================================="
                read id_data_solicitada
	fi
done
data_solicitada="${data_find[$id_data_solicitada]}"
echo "------------->Descompactando o backup: $data_solicitada..."
zcat /var/backup/mysqldump/$data_solicitada/$banco.sql.gz > /var/backup/$banco.sql;
conteiner=`find /var/lib/lxc/mysql -iname "$corrige_unicode_banco" | awk -F'/' '{print $6}' | head -n1`;
echo "Conteiner: $conteiner";
echo "------------->Restaurando..."
lxc-attach -n $conteiner -- mysql -p$pass $banco < /var/backup/$banco.sql;
echo "------------->Desmontando partição de backup..."
rm /var/backup/$banco.sql
umount $backup
echo "------------->Backup finalizado!"
exit;
