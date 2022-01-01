VER="v0.1"

# check environment
[[ $EUID -ne 0 ]] && { echo "You must use sudo to run the OS Builder" ; exit 1 ; } ;

readYnInput () {
	while true; do
	    read -p "$1" YN
	    case $YN in
	        [y] ) break;;
	        [n] ) break;;
	        * ) echo "** Valid entries are y|n";;
	    esac
	done
}


readStrInput () {
    read -p "$1" STR
	readYnInput "** Make corrections (y/n)? "
	if [ $YN = "y" ] ; then
		readStrInput "$1"
	fi
}

smallBanner () {                                                            
    echo "                             @@@@@@@@@@                       "
    echo "                               @@@@@@@@@                      "
    echo "                                @@@@@@@@@@                    "
    echo "                                  @@@@@@@@@@                  "
    echo "                                    @@@@@@@@@,                "
    echo "                                     @@@@@@@@@@               "
    echo "                                       @@@@@@@@@@             "
    echo "                     @@@@@@@@            @@@@@@@@@@           "
    echo " @@@@@@@        @@@@@@@@@@@@@@@@@@        %@@@@@@@@@          "
    echo "@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@        "
    echo " @@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@      "
    echo "           @@@@@@@@@          @@@@@@@@@@        @@@@@@@@@     "
    echo "          @@@@@@@@              @@@@@@@@@        @@@@@@@@@@   "
    echo "          @@@@@@@@               @@@@@@@@@@                   "
    echo "           @@@@@@@@                @@@@@@@@@@                 "
    echo "           @@@@@@@@@@@               @@@@@@@@@#               "
    echo "             @@@@@@@@@@@@@@@@@@       #@@@@@@@@@              "
    echo "               @@@@@@@@@@@@@@@@@@       @@@@@@@@@@            "
    echo "                  .@@@@@@@@@@@@@@@&       @@@@@@@@@%          "
}                                                            

mainBanner () {
	echo "****************************************************************"
	echo "**"
	echo "**  WaBeat Builder $VER"
	echo "**"
	echo "**  Welcome to the automated process for customising"
	echo "**  Rasbian  that runs WaBeat audio player."
    echo "**"
    echo "**  Tested on 2021-10-30-raspios-bullseye-armhf "
    echo "**  This files are based on the wonderful moOde project."    
	echo "**"
}

setHostName () {
    sed -i "s/raspberrypi/Wabeat/" /etc/hostname
	sed -i "s/raspberrypi/Wabeat/" /etc/hosts
	#cp /etc/fake-hwclock.data /etc/ 2> /dev/null
	echo "** Change host name to Wabeat"
}
	
changeUserPassword(){
    echo "** Change password for user pi to Wabeat2pwd"
	echo "pi:Wabeat2pwd" | chpasswd
}

bootConfigFile () {
    echo "** Extract boot config.txt"
	cp bootSource/config.txt.default > /boot/config.txt.default
    cp bootSource/config.txt.default > /boot/config.txt
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: unzip failed"
	fi
}

moodeConfig () {
    echo "** Extract Wabeat boot moodecfg.ini.default"
	cp bootSource/wabeatconfig.ini.default > /boot/wabeatconfig.ini.default
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: unzip failed"
	fi
}
basicOptimizations () {
	echo "** Basic optimizations"
	dphys-swapfile swapoff
	dphys-swapfile uninstall
	systemctl disable dphys-swapfile
	systemctl disable cron.service
	systemctl enable rpcbind
	systemctl set-default multi-user.target
	systemctl stop apt-daily.timer
	systemctl disable apt-daily.timer
	systemctl mask apt-daily.timer
	systemctl stop apt-daily-upgrade.timer
	systemctl disable apt-daily-upgrade.timer
	systemctl mask apt-daily-upgrade.timer
}

refreshOSPacks () {
    echo "** Refresh RaspiOS package list"
    noninteractive apt-get update
    if [ $? -ne 0 ] ; then
		cancelBuild "** Error: refresh failed"
	fi
    echo "** Upgrading RaspiOS installed packages to latest available"
	DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: upgrade failed"
	fi
}

installCorePacks () {
    echo "** Install core packages"
	DEBIAN_FRONTEND=noninteractive apt-get -y install rpi-update php-fpm nginx sqlite3 php-sqlite3 php7.3-gd mpc \
		bs2b-ladspa libbs2b0 libasound2-plugin-equal telnet automake sysstat squashfs-tools shellinabox samba smbclient ntfs-3g \
		exfat-fuse git inotify-tools ffmpeg avahi-utils ninja-build python3-setuptools libmediainfo0v5 libmms0 libtinyxml2-6a \
		libzen0v5 libmediainfo-dev libzen-dev winbind libnss-winbind djmount haveged python3-pip xfsprogs triggerhappy zip id3v2 \
		cmake dos2unix php-yaml sox flac nmap libtool-bin
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Install failed"
	fi
}

cleanPacks() {
    echo "** Clean packages"
    noninteractive apt-get clean
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Cleanup failed"
	fi
}

installMeson () {
    echo "** Install meson"
    wget https://github.com/mesonbuild/meson/releases/download/0.60.3/meson-0.60.3.tar.gz	
	tar xfz meson-0.60.3.tar.gz
	cd meson-0.60.3.tar.gz
	python3 setup.py install
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Install failed"
	fi
    echo "** Clean meson install files"
    cd ..
	rm -rf meson*
}

installMediaInfo () {
    echo "** Install mediainfo"
	cp ./moode/other/mediainfo/mediainfo-18.12 /usr/local/bin/mediainfo
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Install failed"
	fi
}

installAlsaCap () {	
	echo "** Install alsacap"
	cp other/alsacap/alsacap /usr/local/bin
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Install failed"
	fi
}

installGlueDisks () {
    echo "** Install udisks-glue libs"
	DEBIAN_FRONTEND=noninteractive apt-get -y install libatasmart4 libdbus-glib-1-2 libgudev-1.0-0 \
		libsgutils2-2 libdevmapper-event1.02.1 libconfuse-dev libdbus-glib-1-dev
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Install failed"
	fi

	echo "** Install udisks-glue packages"
	dpkg -i ./moode/other/udisks-glue/liblvm2app2.2_2.02.168-2_armhf.deb
	dpkg -i ./moode/other/udisks-glue/udisks_1.0.5-1+b1_armhf.deb
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Install failed"
	fi

	echo "** Install udisks-glue pre-compiled binary"
	cp ./moode/other/udisks-glue/udisks-glue-1.3.5-70376b7 /usr/bin/udisks-glue

	echo "** Install udevil (includes devmon)"
	DEBIAN_FRONTEND=noninteractive apt-get -y install udevil
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: install failed"
	fi

	echo "** Autoremove PHP 7.2"
	DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Autoremove PHP 7.2 failed"
	fi

}

sysCtlConfig () {
    echo "** Systemd enable/disable"
	systemctl enable haveged
	systemctl disable shellinabox
	systemctl disable phpsessionclean.service
	systemctl disable phpsessionclean.timer
	systemctl disable udisks2
	systemctl disable triggerhappy
}
installHostAPMode () {
    echo "** Install Host AP Mode packages"
	noninteractive apt-get -y install dnsmasq hostapd
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: install failed"
	fi

	echo "** Disable hostapd and dnsmasq services"
	systemctl daemon-reload
	systemctl unmask hostapd
	systemctl disable hostapd
	systemctl disable dnsmasq

}

installBlueTooth () {
    echo "** Install Bluetooth packages"
	noninteractive apt-get -y install bluez-firmware pi-bluetooth \
		dh-autoreconf expect libdbus-1-dev libortp-dev libbluetooth-dev libasound2-dev \
		libusb-dev libglib2.0-dev libudev-dev libical-dev libreadline-dev libsbc1 libsbc-dev

	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: install failed"
	fi
}

compileBluez() {
    echo "** Compile bluez"
	# Compile bluez 5.50
	# 2018-06-01 commit 8994b7f2bf817a7fea677ebe18f690a426088367
	cp other/bluetooth/bluez-5.50.tar.xz ./
    # wget www.kernel.org/pub/linux/bluetooth/bluez-5.50.tar.xz
	tar xf bluez-5.50.tar.xz >/dev/null
	cd bluez-5.50
	autoreconf --install
	./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-library
	make
	make install
	cd ..
	rm -rf ./bluez-5.50*
	echo "** Delete symlink and bin for old bluetoothd"
	rm /usr/sbin/bluetoothd
	rm -rf /usr/lib/bluetooth
	echo "** Create symlink for new bluetoothd"
	ln -s /usr/libexec/bluetooth/bluetoothd /usr/sbin/bluetoothd
}

installbluezAlsa () {
    echo "** Compile bluez-alsa"
	# Compile bluez-alsa 3.0.0
	cp ./other/bluetooth/bluez-alsa-3.0.0.zip ./
	unzip -q bluez-alsa-3.0.0.zip
	cd bluez-alsa-3.0.0
	echo "** NOTE: Ignore warnings from autoreconf and configure"
	autoreconf --install
	mkdir build
	cd build
	../configure --disable-hcitop --with-alsaplugindir=/usr/lib/arm-linux-gnueabihf/alsa-lib
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Configure failed"
	fi

	make
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Make failed"
	fi

	make install
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Make install failed"
	fi

	cd ../..
	rm -rf ./bluez-alsa-3.0.0

	echo "** Check for default bluealsa.service file"
	if [ ! -f /lib/systemd/system/bluealsa.service ] ; then
		echo "** Creating default bluealsa.service file"
		echo "#" > /lib/systemd/system/bluealsa.service
		echo "# Created by Wabeat OS Builder" >> /lib/systemd/system/bluealsa.service
		echo "# The corresponfing file in /etc/systemd/system takes precedence" >> /lib/systemd/system/bluealsa.service
		echo "#" >> /lib/systemd/system/bluealsa.service
		echo "[Unit]" >> /lib/systemd/system/bluealsa.service
		echo "Description=BluezAlsa proxy" >> /lib/systemd/system/bluealsa.service
		echo "Requires=bluetooth.service" >> /lib/systemd/system/bluealsa.service
		echo "After=bluetooth.service" >> /lib/systemd/system/bluealsa.service
		echo >> /lib/systemd/system/bluealsa.service
		echo "[Service]" >> /lib/systemd/system/bluealsa.service
		echo "Type=simple" >> /lib/systemd/system/bluealsa.service
		echo "ExecStart=/usr/bin/bluealsa" >> /lib/systemd/system/bluealsa.service
		echo >> /lib/systemd/system/bluealsa.service
		echo "[Install]" >> /lib/systemd/system/bluealsa.service
		echo "WantedBy=multi-user.target" >> /lib/systemd/system/bluealsa.service
		echo >> /lib/systemd/system/bluealsa.service
	fi
}

disableBluetoothServices () {
    echo "** Disable bluetooth services"
	systemctl daemon-reload
	systemctl disable bluetooth.service
	systemctl disable bluealsa.service
	systemctl disable hciuart.service
	mkdir -p /var/run/bluealsa
	sync
}

installWirePi () {
    echo "** Install WiringPi"
	# NOTE: Ignore warnings during build

	cp ./other/wiringpi/wiringPi-2.50-36fb7f1.tar.gz ./
    # wget https://github.com/WiringPi/WiringPi/releases/tag/final_official_2.50
	tar xfz ./wiringPi-2.50-36fb7f1.tar.gz
	cd wiringPi-36fb7f1
	./build

	if [ $? -ne 0 ] ; then
		cancelBuild "** Install failed"
	fi

    cd ..
	rm -rf ./wiringPi*
}

installRotEnc () {
    echo "** Compile C version of rotary encoder driver"
	cp ./other/rotenc/rotenc.c ./
	gcc -std=c99 rotenc.c -orotenc -lwiringPi
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Compile failed"
	fi

	echo "** Install C version of driver"
	cp ./rotenc /usr/local/bin/rotenc_c
	rm ./rotenc*

	echo "** Compile C version of rotary encoder driver"
	cp ./other/rotenc/rotenc.c ./
	gcc -std=c99 rotenc.c -orotenc -lwiringPi
	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: Compile failed"
	fi

	echo "** Install C version of driver"
	cp ./rotenc /usr/local/bin/rotenc_c
	rm ./rotenc*

	echo "** Install RPi.GPIO"
	pip3 install RPi.GPIO

	if [ $? -ne 0 ] ; then
		cancelBuild "** Install failed"
	fi

	echo "** Install musicpd"
	pip3 install python-musicpd

	if [ $? -ne 0 ] ; then
		cancelBuild "** Install failed"
	fi

	echo "** Install Python version of rotary encoder driver (default)"
	cp ./other/rotenc/rotenc.py /usr/local/bin/rotenc

	if [ $? -ne 0 ] ; then
		cancelBuild "** Install failed"
	fi
}

createMPDruntime () {
    echo "** Create MPD runtime environment"
	useradd mpd
	mkdir /var/lib/mpd
	mkdir /var/lib/mpd/music
	mkdir /var/lib/mpd/playlists
	touch /var/lib/mpd/state
	chown -R mpd:audio /var/lib/mpd
	mkdir /var/log/mpd
	touch /var/log/mpd/log
	chmod 644 /var/log/mpd/log
	chown -R mpd:audio /var/log/mpd
	cp ./mpd/mpd.conf.default /etc/mpd.conf
	chown mpd:audio /etc/mpd.conf
	chmod 0666 /etc/mpd.conf
	echo "** Set permissions for D-Bus (for bluez-alsa)"
	usermod -a -G audio mpd

}

installMPDDevpck () {
    echo "** Install MPD dev lib packages"
	noninteractive apt-get -y install \
	libyajl-dev \
	libasound2-dev \
	libavahi-client-dev \
	libavcodec-dev \
	libavformat-dev \
	libbz2-dev \
	libcdio-paranoia-dev \
	libcurl4-gnutls-dev \
	libfaad-dev \
	libflac-dev \
	libglib2.0-dev \
	libicu-dev \
	libid3tag0-dev \
	libiso9660-dev \
	libmad0-dev \
	libmpdclient-dev \
	libmpg123-dev \
	libmp3lame-dev \
	libshout3-dev \
	libsoxr-dev \
	libsystemd-dev \
	libvorbis-dev \
	libwavpack-dev \
	libwrap0-dev \
	libzzip-dev \
	libpcre++-dev

	if [ $? -ne 0 ] ; then
		cancelBuild "** Error: install failed"
	fi
}
##//////////////////////////////////////////////////////////////
##
## MAIN
##
##//////////////////////////////////////////////////////////////

# STEP 1
smallBanner
mainBanner
setHostName
# reboot 

# Step 2
changeUserPassword
bootConfigFile
# reboot

# STEP 3A - apt update & upgrade"
basicOptimizations
refreshOSPacks
# reboot

#  STEP 3B - Install core packages"
installCorePacks
cleanPacks
#installMeson
#cleanPacks
#installMediaInfo
installAlsaCap
#installGlueDisks
sysCtlConfig
# STEP 4 - Install enhanced networking" (NO REBOOT!)
installHostAPMode
installBlueTooth
compileBluez
installbluezAlsa
cleanPacks
# reboot

# STEP 5 - Install Rotary encoder driver
#installWirePi
# STEP 6 - Install MPD and MPC" (NO REBOOT!)
createMPDruntime
installMPDDevpck


#reboot
