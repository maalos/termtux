#!/data/data/com.termux/files/usr/bin/bash
cd ~

tarball=void-rootfs.tar.gz
dir=void-fs
version=20210930

if [ -d "$dir" ]; then
    exists=1
    echo "Folder exists, skipping downloading"
fi

if [ "$exists" != 1 ]; then
    case `dpkg --print-architecture` in
	aarch64)
	    arch="aarch64" ;;
	arm)
	    arch="armhf" ;;
	amd64)
	    arch="x86_64" ;;
	x86_64)
	    arch="x86_64" ;;
    i386)
        arch="i386" ;;
	*)
	    echo "Unknown/Unsupported CPU architecture, exiting..."; exit 1 ;;
	esac

	wget "https://alpha.de.repo.voidlinux.org/live/current/void-${arch}-ROOTFS-${version}.tar.xz" -O $tarball
    cur=`pwd`
    mkdir -p "$dir" && cd "$dir"
    echo "Decompressing rootfs, please wait..."
    proot --link2symlink tar -xf ${cur}/${tarball}||:
    cd "$cur"
fi

mkdir -p void-binds
bin=start-void.sh
echo "Writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r ${dir}"
if [ -n "\$(ls -A void-binds)"  ]; then
        for f in void-binds/* ;do
                  . \$f
                      done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b ${dir}/root:/dev/shm"
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
exec ${command}
EOM

echo "Fixing shebang of $bin"
termux-fix-shebang $bin
echo "Making $bin executable"
chmod +x $bin
echo "Removing tarball to free up some space"
rm $tarball
echo "Done. Launch Void using ./${bin}"
