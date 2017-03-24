#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'

confs=`cat /tmp/ss_conf_backup.txt`
format=`echo $confs|grep "{"`
if [ -z "$format" ];then
	echo_date 检测到ss备份文件...
	cat /tmp/ss_conf_backup.txt | sed '/webtest/d' | sed '/ping/d' |sed '/ss_node_table/d' |sed '/_state_/d' > /tmp/ss_conf_backup_tmp.txt
	echo_date 开始恢复配置...
	while read conf
	do
	#echo_date $conf
		dbus set $conf >/dev/null 2>&1
	done < /tmp/ss_conf_backup_tmp.txt

	backup_version=`dbus get ss_basic_version_local`
	comp=`versioncmp $backup_version 3.0.6`
	if [ "$comp" == "1" ];then
		echo_date 检测到备份文件来自低于3.0.6版本，开始对部分数据进行base64转换，以适应新版本！
		node_pass=`dbus list ssconf_basic_password |cut -d "=" -f 1|cut -d "_" -f4|sort -n`
		for node in $node_pass
		do
			dbus set ssconf_basic_password_$node=`dbus get ssconf_basic_password_$node|base64_encode`
		done
		dbus set ss_basic_password=`dbus get ss_basic_password|base64_encode`
		dbus set ss_basic_black_lan=`dbus get ss_basic_black_lan | base64_encode`
		dbus set ss_basic_white_lan=`dbus get ss_basic_white_lan | base64_encode`
		dbus set ss_ipset_black_domain_web=`dbus get ss_ipset_black_domain_web | base64_encode`
		dbus set ss_ipset_white_domain_web=`dbus get ss_ipset_white_domain_web | base64_encode`
		dbus set ss_ipset_dnsmasq=`dbus get ss_ipset_dnsmasq | base64_encode`
		dbus set ss_ipset_black_ip=`dbus get ss_ipset_black_ip | base64_encode`
		dbus set ss_redchn_isp_website_web=`dbus get ss_redchn_isp_website_web | base64_encode`
		dbus set ss_redchn_dnsmasq=`dbus get ss_redchn_dnsmasq | base64_encode`
		dbus set ss_redchn_wan_white_ip=`dbus get ss_redchn_wan_white_ip | base64_encode`
		dbus set ss_redchn_wan_white_domain=`dbus get ss_redchn_wan_white_domain | base64_encode`
		dbus set ss_redchn_wan_black_ip=`dbus get ss_redchn_wan_black_ip | base64_encode`
		dbus set ss_redchn_wan_black_domain=`dbus get ss_redchn_wan_black_domain | base64_encode`
		dbus set ss_game_dnsmasq=`dbus get ss_game_dnsmasq | base64_encode`
		dbus set ss_gameV2_dnsmasq=`dbus get ss_gameV2_dnsmasq | base64_encode`
	fi

	dbus set ss_basic_enable="0"
	dbus set ss_basic_version_local=`cat /koolshare/ss/version` 
	
	echo_date 配置恢复成功！
	
else
	echo_date 检测到json配置文件...
	servers=$(cat /tmp/ss_conf_backup.txt |grep -w server|sed 's/"//g'|sed 's/,//g'|cut -d ":" -f 2)
	ports=`cat /tmp/ss_conf_backup.txt |grep -w server_port|sed 's/"//g'|sed 's/,//g'|cut -d ":" -f 2`
	passwords=`cat /tmp/ss_conf_backup.txt |grep -w password|sed 's/"//g'|sed 's/,//g'|cut -d ":" -f 2`
	methods=`cat /tmp/ss_conf_backup.txt |grep -w method|sed 's/"//g'|sed 's/,//g'|cut -d ":" -f 2`
	remarks=`cat /tmp/ss_conf_backup.txt |grep -w remarks|sed 's/"//g'|sed 's/,//g'|cut -d ":" -f 2`
	
	# flush previous test value in the table
	echo_date 尝试移除旧的webtest结果...
	webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
		for line in $webtest
		do
			dbus remove "$line"
		done
	
	# flush previous ping value in the table
	echo_date 尝试移除旧的ping测试结果...
	pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
		for ping in $pings
		do
			dbus remove "$ping"
		done
	
	echo_date 开始导入配置...导入json配置不会覆盖原有配置.
	last_node=`dbus list ssconf_basic_server|cut -d "=" -f 1| cut -d "_" -f 4| sort -nr|head -n 1`
	if [ ! -z "$last_node" ];then
	k=`expr $last_node + 1`
	else
	k=1
	fi
	min=1
	max=`cat /tmp/ss_conf_backup.txt |grep -wc server`
	while [ $min -le $max ]
	do
	    echo_date "==============="
	    echo_date import node $min
	    echo_date $k
	    
	    server=`echo $servers | awk "{print $"$min"}"`
		port=`echo $ports | awk "{print $"$min"}"`
		password=`echo $passwords | awk "{print $"$min"}"`
		method=`echo $methods | awk "{print $"$min"}"`
		remark=`echo $remarks | awk "{print $"$min"}"`
		
		echo_date $server
		echo_date $port
		echo_date $password
		echo_date $method
		echo_date $remark
		
		dbus set ssconf_basic_server_"$k"="$server"
		dbus set ssconf_basic_port_"$k"="$port"
		dbus set ssconf_basic_password_"$k"="$password"
		dbus set ssconf_basic_method_"$k"="$method"
		dbus set ssconf_basic_name_"$k"="$remark"
	    min=`expr $min + 1`
	    k=`expr $k + 1`
	done

	echo_date 检测到你使用了json文件，开始对部分数据进行base64转换，以适应新版本！
	node_pass=`dbus list ssconf_basic_password |cut -d "=" -f 1|cut -d "_" -f4|sort -n`
	for node in $node_pass
	do
		dbus set ssconf_basic_password_$node=`dbus get ssconf_basic_password_$node|base64_encode`
	done
	dbus set ss_basic_password=`dbus get ss_basic_password|base64_encode`
	echo_date 导入配置成功！
fi
	echo_date 一点点清理工作...
	sleep 2
	rm -rf /tmp/ss_conf*
	rm -rf /tmp/ss_conf_backup.txt
	rm -rf /tmp/ss_conf_backup_tmp.txt
	echo_date 完成！
