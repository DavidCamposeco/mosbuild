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

sethostname () {
    sed -i "s/raspberrypi/moode/" part2/etc/hostname
	sed -i "s/raspberrypi/moode/" part2/etc/hosts
	cp /etc/fake-hwclock.data part2/etc/ 2> /dev/null
	echo "** Change host name to moode"
}
	

##//////////////////////////////////////////////////////////////
##
## MAIN
##
##//////////////////////////////////////////////////////////////
smallBanner
mainBanner

#directYBanner
