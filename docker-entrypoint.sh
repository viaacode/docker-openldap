#!/bin/bash
set -x
if [ -z "$1" ] || [ "${1:0:1}" == '-' ]; then
    set -- slapd -d1 -h ldap://:$LdapPort/ "$@"
fi

if [ $(basename $1) == 'slapd' ]; then 
    # start ldap for config only (intenal socket, not exposed)
    /usr/sbin/slapd -h ldapi:///

    # run initial config only if a backend does not yet exists
    if ! ldapsearch -LLL -H ldapi:/// -Y external -b cn=config 'olcSuffix=*' dn | grep ^dn:
    then

        if [ -n "$LDAP_SUFFIX" ]; then
            #[ -z "$LDAP_ROOT_PASSWORD" ] && LDAP_ROOT_PASSWORD=$(pwgen -1 32) && echo $LDAP_ROOT_PASSWORD
            sed -r -e "s/%SUFFIX%/$LDAP_SUFFIX/g" /backend.ldif | \
            sed -r -e "s/%ROOT_PASSWORD%/$LDAP_ROOT_PASSWORD/g" | \
            ldapadd -v -H ldapi:/// -Y external
        fi

        for f in $(ls /docker-entrypoint-init/*ldif 2>/dev/null); do
            grep -qi ^changetype: $f
            [ $? -eq 0 ] && Command=ldapmodify || Command=ldapadd
            $Command -v -H ldapi:/// -Y external -f $f
        done
    fi
    pkill slapd
    while killall -s0 slapd 2>/dev/null; do sleep 1; done
fi

exec $@ 
