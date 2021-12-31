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
	echo "**  Welcome to the automated process for creating a"
	echo "**  custom Linux OS that runs WaBeat audio player."
    echo "**  This files are based on the wonderful moOde project."
	echo "**"
	echo "**  1. You will need a Raspberry Pi running RaspiOS with SSH"
	echo "**  enabled and at least 2.5 GB free space on the boot SDCard."
	echo "**"
	echo "**  2. The build can be written directly to the boot SDCard or"
	echo "**  to a second USB-SDCard plugged into the Raspberry Pi."
	echo "**"
	echo "**  WARNING: RaspiOS Buster Lite 2020-12-02 must be used if"
	echo "**  building directly on the boot SDCard. It must be a fresh,"
	echo "**  unmodified installation of RaspiOS Lite otherwise the build"
	echo "**  results cannot be guaranteed."
	echo "**"
	echo "**  Be sure to backup the SDCard used to boot your Pi!"
	echo "**"
	echo "****************************************************************"
	echo
    readYnInput "** Write OS build directly to the boot SDCard (y/n)? "
	if [ $YN = "y" ] ; then
		DIRECT="y"
	fi
}

cancelBuild () {
	if [ $# -gt 0 ] ; then
		echo "$1"
	fi
	echo "** OS build cancelled"
	ls mosbuild/*.img > /dev/null 2>&1
	# if no image files present remove the dir
	if [ $? -ne 0 ] ; then
		rm -rf ./mosbuild 2> /dev/null
	fi
    rm -f mosbuild.properties 2> /dev/null
	rm -f mosbuild_worker.sh 2> /dev/null
	rm -f mosbuild_befor_usb.txt 2> /dev/null
	rm -f mosbuild_after_usb.txt 2> /dev/null
	exit 1
}

directYBanner () {
	echo
	echo "////////////////////////////////////////////////////////////////"
	echo "//"
	echo "// STEP 1 - Writing OS directly to boot SDCard"
	echo "//"
	echo "////////////////////////////////////////////////////////////////"
	echo

	readYnInput "** Do you have a backup of your boot SDCard (y/n)? "
	if [ $YN = "n" ] ; then
		cancelBuild
	fi

	readStrInput "** Enter current date (YYYY-MM-DD) "
	date --set $STR > /dev/null 2>&1    
	if [ $? -ne 0 ] ; then
		echo "** Error: Invalid date format"
		readYnInput "** Reenter date (y/n)? "
		if [ $YN = "y" ] ; then
			readStrInput "** Enter current date (YYYY-MM-DD) "
		else
			cancelBuild
		fi
	fi
}
#### OPTIONS MANAGER
getOptions () {
	#echo "** Options configuration:"
	#echo
	#echo "   There are only two build options that can be configured. The"
	#echo "   1st is Proxy Server. Set it to 'n' unless you are certain that"
	#echo "   your network requires proxied access to the Internet. The 2nd"
	#echo "   is WiFi connection. For maximum speed and reliability set this"
	#echo "   to 'n' and use an Ethernet connection for the Build."
	#echo
    echo "No options for wireless or Proxy at the moment"
	#NUMOPT=2
	#IDXOPT=1
	#proxyServer
	#useWireless
	#squashFs
	#updatedKernel
	#addlComponents

	# if the var does not exist then = n
	#SQUASH_FS=y
	LATEST_KERNEL=y
	ADDL_COMPONENTS=y
}

##//////////////////////////////////////////////////////////////
##
## MAIN
##
##//////////////////////////////////////////////////////////////
smallBanner
#directYBanner
getOptions