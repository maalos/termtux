#!/data/data/com.termux/files/usr/bin/bash
cd ~

tarball=alpine-minirootfs.tar.gz
dir=alpine-fs
version=3.15.4

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
	i*86)
	    arch="x86" ;;
	x86)
	    arch="x86" ;;
	*)
	    echo "Unknown CPU architecture, exiting..."; exit 1 ;;
	esac

	wget "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${arch}/alpine-minirootfs-${version}-${arch}.tar.gz" -O $tarball
    cur=`pwd`
    mkdir -p "$dir" && cd "$dir"
    echo "Decompressing rootfs, please wait..."
    proot --link2symlink tar -xf ${cur}/${tarball}||:
    cd "$cur"
fi

mkdir -p alpine-binds
bin=start-alpine.sh
echo "Writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $dir"
if [ -n "\$(ls -A alpine-binds)"  ]; then
    for f in alpine-binds/* ;do
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
command+=" PATH=PATH=/bin:/usr/bin:/sbin:/usr/sbin"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/sh --login"
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
rm $dir/etc/resolv.conf
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > $dir/etc/resolv.conf
echo "Done. Launch alpine using ./${bin}"
