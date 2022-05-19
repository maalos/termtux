#!/data/data/com.termux/files/usr/bin/bash
cd ~

pkg install wget openssl-tool proot -y
hash -r

clear
echo -e "1. Ubuntu 22.04\n2. Alpine 3.15.4\n3. Void 2021-09-30"
read choice

case $choice in
1)
    os=ubuntu ;;
2)
    os=alpine ;;
3)
    os=void ;;
*)
    echo "Incorrect choice, exiting..."; exit 1 ;;
esac

wget "https://raw.githubusercontent.com/maalos/termtux/main/scripts/${os}.sh" && bash ${os}.sh
