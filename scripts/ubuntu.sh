#!/data/data/com.termux/files/usr/bin/bash
cd ~

tarball=ubuntu-minirootfs.tar.gz
dir=ubuntu-fs
version=22.04

if [ -d "$dir" ]; then
    exists=1
    echo "Folder exists, skipping downloading"
fi

if [ "$exists" != 1 ]; then
    case `dpkg --print-architecture` in
	aarch64)
	    arch="arm64" ;;
	arm)
	    arch="armhf" ;;
	amd64)
	    arch="amd64" ;;
	x86_64)
	    arch="amd64" ;;
	*)
	    echo "Unknown/Unsupported CPU architecture, exiting..."; exit 1 ;;
	esac

	wget "https://cdimage.ubuntu.com/ubuntu-base/releases/${version}/release/ubuntu-base-${version}-base-${arch}.tar.gz" -O $tarball
    cur=`pwd`
    mkdir -p "$dir" && cd "$dir"
    echo "Decompressing rootfs, please wait..."
    proot --link2symlink tar -xf ${cur}/${tarball}||:
    cd "$cur"
fi

mkdir -p ubuntu-binds
bin=start-ubuntu.sh
echo "Writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A ubuntu-binds)"  ]; then
        for f in ubuntu-binds/* ;do
                  . \$f
                      done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b ubuntu-fs/root:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to /
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\(" ];then
        exec \$command
    else
        \$command -c "\$com"
fi
EOM

echo "Fixing shebang of $bin"
termux-fix-shebang $bin
echo "Making $bin executable"
chmod +x $bin
echo "Removing tarball to free up some space"
rm $tarball
echo "Done. Launch Ubuntu using ./${bin}"
