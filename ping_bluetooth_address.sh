#!/bin/bash

# 	Author: 	Dex
# 	Date:		2018/03/30
# 	Purpose:	This script is used to ping bluetooth devices and send alerts when they either leave or arrive

root_dir=${BLUETOOTH_PRESENCE_ALERTER_ROOT}
state_file=${root_dir}/state
bot_properties=${root_dir}/telegram_bot_properties.props
device_list=${root_dir}/device_list.lst
retry_count=15
sleep_interval=10

check_for_state(){
	if [[ ! -f ${state_file} ]]
	then
		echo "State file missing, creating it"
		touch ${state_file}
	fi

}

check_if_bot_file_exists(){
	if [[ ! -f ${bot_properties} ]]
	then
		echo "Bot key file is missing, alerting will not go to telegram..."
		return 1
	fi
	#file exists, so return 0
	return 0
}

send_alert(){
	state=${1}
	person=${2}

	if [[ ${state} == 0 ]]
	then
		message="${person} is now at home"
	else
		message="${person} is no longer at home"
	fi
	
	echo "${message}"

        check_if_bot_file_exists
        bot_key_avail=${?}

	#This section is for the bot alerting, if config is available
	if [[ ${bot_key_avail} == 0 ]]
	then
		while read props || [[ -n "$props" ]]; do
			bot_key=`echo ${props} | cut -d"|" -f1`
			chat_id=`echo ${props} | cut -d"|" -f2`
			echo "Sending bot alert now"
			send_bot_alert "${bot_key}" "${chat_id}" "${message}"
		done < ${bot_properties}
	fi
}

send_bot_alert(){
	bot_key=${1}
	chat_id=${2}
	message=${3}

	curl -s -X POST https://api.telegram.org/bot${bot_key}/sendMessage -d text="${message}" -d chat_id="${chat_id}" >> /dev/null

}

compare_states(){
	new_state=${1}
	old_state=${2}
	device=${3}
	person=${4}

	if [[ ! "${new_state}" == "${old_state}" ]]
	then
		set_state ${device} ${new_state} ${state_file} ${person}
		send_alert "${new_state}" "${person}"
	fi
}

check_device_in_state(){
	mac_address=${1}
	ping_result=${2}
	person=${3}

	state_from_file=`grep "${person}|${mac_address}" ${state_file}`
	exists=$?
	if [[ ${exists} == 1 ]]
	then
		echo "${person}|${mac_address}=${ping_result}" >> ${state_file}
	else
		new_state=`echo ${state_from_file} | cut -d"=" -f2`
		compare_states ${ping_result} ${new_state} ${mac_address} ${person}
	fi
}

set_state(){
	device=${1}
	new_state=${2}
	state_file=${3}
	person=${4}

	awk -v pat="^${person}|${device}=" -v value="${person}|${device}=${new_state}" '{ if ($0 ~ pat) print value; else print $0; }' $3 > $3.tmp
	mv $3.tmp $3
}

ping_address(){
	mac_address=${1}
	count=0
	until [[ ${count} -ge ${retry_count} ]]
	do
		count=$((count+1))
		echo "Attempt ${count}/${retry_count}"
		sudo l2ping -c1 ${mac_address} > /dev/null
		result=${?}
		if [[ ${result} == 0 ]]
		then
			return 0
		fi
	done
	return 1
}

process_device_file(){
	while read -r device || [[ -n "$device" ]]; do
        	person=`echo ${device} | cut -d"=" -f1`
        	mac_address=`echo ${device} | cut -d"=" -f2`
	
        	echo "Checking [${person}]'s device: ${mac_address}"
        	ping_address ${mac_address}
        	ping_result=${?}
	
        	check_device_in_state ${mac_address} ${ping_result} ${person}
	done < ${device_list}
}

#First check if state file exists
check_for_state

#Loop indefinitely with sleeps inbetween
while true
do
	echo `date`
	process_device_file
	echo
	sleep ${sleep_interval}
done

