genssh() {
    force=false
    while getopts 'fh' OPTION; do
      case "$OPTION" in
        f)
            echo "removing existent local keys ..."
            force=true
            rm ~/.ssh/id_ed25519*
            ;;
        h)
            echo "script usage: genssh [-f (force)] [-h (help)]"
            return
            ;;
        ?)
            echo "script usage: genssh [-f (force)] [-h (help)]"
            return 1
            ;;
      esac
    done
    shift "$(($OPTIND -1))"

    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        ldapIP=`dig +short ldap` 
        domain=`hostname -d`
        dn=dc=${domain//./,dc=}

        ldapsearch -x -b "$dn" -H ldap://$ldapIP '(&(objectClass=posixAccount)(uid='"$USER"'))'|grep -q sshPublicKey   
        if [ $? -ne 0 ] || $force; then
            ssh-keygen -t ed25519 -q -N '' <<<'' >/dev/null
            echo -e "Propagate new public key to LDAP dn: uid=$USER,ou=People,$dn\n"
            pubKey=`cat ~/.ssh/id_ed25519.pub`
            echo -ne "For cn=admin,$dn "
            ldapmodify -x -D "cn=admin,$dn" -H ldap://$ldapIP -W <<LDIF
dn: uid=$USER,ou=People,$dn
changetype: modify
replace: sshPublicKey
sshPublicKey: $pubKey
LDIF
        else
            echo -e "Public-key LDAP entry found for dn: uid=$USER,ou=People,$dn\nTake a look for your existing private key - nothing to do"
        fi    

    else
        echo "SSH-keys have alredy been created! - Exit"
    fi
}
