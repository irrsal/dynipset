#!/usr/bin/env bash

CONFIG="/etc/dynipset/config.json"
TIMEOUT=$(jq -r .timeout $CONFIG)
SET4=$(jq -r .set4 $CONFIG)
SET6=$(jq -r .set6 $CONFIG)
HOSTS=$(jq -r '[ .hosts[] | .fqdn ] | join(" ")' $CONFIG)

add_set () {
	SET_NAME="$1"
	IP="$2"
	EXPIRED=false

	SETELEM=$(nft -j list ruleset | \
		jq ".nftables[].set | \
		select(.name==\"$SET_NAME\") | \
		.elem[]? | \
		select(.elem.val==\"$IP\")")
	if [[ "$SETELEM" && $TIMEOUT -gt 0 ]]
	then
		EXP=$(echo $SETELEM | jq ".elem.expires")
		if [[ $EXP -lt $TIMEOUT ]]
		then
			EXPIRED=true
		fi
	fi

	if [[ -z "$SETELEM" || "$EXPIRED" = true ]]
	then
		if [[ $TIMEOUT -gt 0 ]]
		then
			/usr/sbin/nft -f - <<-EOF
			add element inet filter $SET_NAME { $IP }
			delete element inet filter $SET_NAME { $IP }
			add element inet filter $SET_NAME { $IP } 
			EOF
		else
			nft add element inet filter $SET_NAME { $IP }
		fi
	fi
}

for HOST in $HOSTS
do
	for IP4ADDR in $(getent ahostsv4 $HOST | \
		grep -i STREAM | \
		awk '{ print $1 }')
	do
		add_set $SET4 $IP4ADDR
	done

	for IP6ADDR in $(getent ahostsv6 $HOST | \
		grep -i STREAM | \
		awk '{ print $1 }')
	do
		add_set $SET6 $IP6ADDR
	done
done

