#!/bin/bash

# Function defined start

fancyelip () {
    if [ "$1" == "" ]; then elipdelay="0.1"; else elipdelay="$1"; fi
    for ((n=0;n<3;n++)); do sleep "$elipdelay" && echo -n "."; done
}

# Function defined end

[ "$(uname -s)" == "*Darwin*" ] && echo "Current operating system is OSX. This script is completely untested on OSX and you may encounter wild and fantastical errors. Proceed at your own risk."

cd "$(dirname "$0")" || exit 1

templatefilename="AApersonTemplate.xml"

if [[ $PWD != *"test1" ]] && [[ $PWD != *"people" ]]; then # Error condition 1: Is the working directory correct? Valid working directories are test1 or people
    echo "You're not in the right directory. Please change directory to either test1 or people."
    exit 1
fi
if [[ ! -f ../$templatefilename ]] && [[ ! -f ./$templatefilename ]] && [[ ! -f ./people/$templatefilename ]]; then # Error condition 2: Is the template file, as defined at the beginning, available?
    echo "Template file not found! Check your current working directory."
    exit 1
fi

if [ "$1" == "" ]; then
    clistart=0
    read -p "Enter person ID: " nameorid # ID or three letters or full path, quod libet
    work="$nameorid"
else
    clistart=1
    work="$1"
fi

templatefile=$(find . -type f -path "*/$templatefilename" -prune) # TODO this assumes only one templatefile with the templatefilename... That's gotta be solved somehow
echo -ne "Template file in use: \033[1;35m$templatefile\033[0m.\n"

if [[ "$work" == ????? ]] && [[ "$work" != ?????".xml" ]]; then # checks input to see if it's a persid. three letters only, or full path
    if [[ "$PWD" == *"test1" ]]; then newfile="./people/$work.xml"
    elif [[ "$PWD" == *"people" ]]; then newfile="./$work.xml"
    fi
    persid="$work"
elif [[ "$work" == ??? ]] && [[ "$work" =~ ^[A-Z]+$ ]]; then
    if [[ "$PWD" == *"test1" ]]; then newfile="./people/$work""01.xml"
    elif [[ "$PWD" == *"people" ]]; then newfile="./$work""01.xml"
    fi
    persid="$work""01"
elif [[ "$PWD" == *"people" ]] || [[ "$PWD" == *"test1" ]]; then # below is for backwards compatibility with primitive workflow that deals with raw file paths; kinda bork
    newfile="$work" # this is like this because ideally you would use the shell's autocomplete function to check if a name is taken, and thus write ./people/XXX99.xml if you're in test1/ or ./XXX99.xml if you're in people/
    persid=${newfile%.xml} && persid=${persid##*/} # extracts the code id from the filename, since they are one in the same.
else
    echo "Something's wrong."
    exit 1
fi

if [[ ${newfile: -4} == ".xml" ]]; then
    echo -n "Filename extension seems right! "
else
    echo -n "Filename extension lacks .xml, adding... "
    newfile="$newfile.xml"
fi

echo -ne "Current person ID value: \033[0;32m$persid\033[0m.\nChecking filename validity" && fancyelip; echo -ne " " # Literally cosmetic and pointless, but it looks cool though.

if [[ ${newfile: -9} == ?????".xml" ]] && [[ "$((10#${persid:3:2}))" -le "99" ]] && [[ "$((10#${persid:3:2}))" -ge "1" ]]; then # Checks if filename has exactly 5 characters then checks if the last two characters are numbers between 1-99 inclusive
    echo "Filename seems to follow the 5 char convention!"
else
    echo "That name doesn't quite seem right. Try again?"
    sleep 10
    exit 1
fi

new=$((10#${persid: -2}))

if [ -f "$newfile" ]; then
    echo -ne "\033[0;31mFile already exists\033[0m! Attempting to fix filename to not conflict. "
    if [[ "$PWD" == *"test1" ]]; then
        if [[ ! $(uname -o) == "GNU/Linux" ]]; then echo "If you're stuck on this, please be patient and let it run its course. This can occur the first time the script used after starting the operating system."; fi
        switch2="people/"
    elif [[ "$PWD" == *"test1/people" ]]; then
        switch2=""
    else
        echo "You're in the wrong directory. How is that possible? We checked above!"
        exit 1
    fi

    cur=$(find ./$switch2 -maxdepth 1 -path "*${persid:0:3}*xml" | sort | tail -n 1)
    cur=${cur%.xml} && cur=${cur##*/}; cur=${cur: -2}; cur=$((10#0$cur)) # grabs current persid
    new=$((10#$((new+$((cur-new))+1))))

    if [ $new -le "9" ]; then new="0$new"; fi
    persid="${persid:0:3}$new"
    if [[ "$PWD" == "*test1/people*" ]]; then
        newfile="./$persid.xml"
    else
        newfile="./people/$persid.xml"
    fi
    echo -e "New person ID: \033[0;32m$persid\033[0m."
    if [ -f "$newfile" ]; then echo "We've failed." && sleep 3 && exit 1; fi
fi

#
# Error checking and prelude done, actual work starts here
#

echo -e "Creating \033[0;32m$newfile\033[0m."

cp --no-clobber "$templatefile" "$newfile" || echo "Something is still wrong."

echo "Writing in person ID and formatting XML file with sed."

if [[ $(grep "XXX99" "$newfile") != "" ]]; then
    sed -i "s/xml:id=\"XXX99\"/xml:id=\"$persid\"/g" "$newfile"
elif [[ $(grep "XXX01" "$newfile") != "" ]]; then
    sed -i "s/xml:id=\"XXX01\"/xml:id=\"$persid\"/g" "$newfile"
fi

[ ! "$2" == "" ] && sed -i "s/sex=\"1\"/sex=\"$2\"/g" "$newfile"

if [ "$(uname -o)" == "GNU/Linux" ] && ( command -v kate >/dev/null 2>&1 ); then # this is my personal thing, don't worry about it!
    echo "Opening with kate." && kate "$newfile"
elif [ "$(uname -o)" == "Msys" ]; then # automatically opens up Oxygen for editing. A bit slow but that's on the part of Oxygen.
    oxxmlloc="/c/Program Files/Oxygen XML Editor 27/oxygen.bat"
    if [ -f "$oxxmlloc" ]; then
        "$oxxmlloc" file:"$newfile" 2>/dev/null &
        echo -n "Found Oxygen XML Editor. Opening now. Please wait a few seconds" && fancyelip "0.3"; echo ""
    elif [ ! -f "$oxxmlloc" ]; then
        echo "Did not find Oxygen XML Editor at expected location. Trying again..."
        curveball="$(find "/c/Program Files/" -maxdepth 2 -path "*oxygen.bat" 2>/dev/null)"
        [ ! "$curveball" == "" ] && ( "$curveball" file:"$newfile" 2>/dev/null & )
    fi
# else
#     echo "I don't know what OS you're running. So I'm just going to try to open a text editor. Good luck."
#     editor "$newfile" || nano "$newfile"
fi

if [ $clistart == 0 ]; then
    echo "Script will close in 10 seconds. To close immediately, press Control + C."
    sleep 10
fi

exit 0

# ================ Archived code that exists for no particular reason ================
# echo "You're probably in the right directory, and the template file is probably available."
# Dependency check: xmlstarlet; below works maybe
# if ( ! type "xmlstarlet" > /dev/null ) && ( ! type "xml" > /dev/null ) ; then
# if ( command -v xmlstarlet >/dev/null 2>&1 ) && ( command -v xml >/dev/null 2>&1 ); then
#     echo -e "You don't have xmlstarlet installed. This is a required dependency for this script.\nPlease go here to install xmlstarlet: https://sourceforge.net/projects/xmlstar/files/xmlstarlet/1.6.1/xmlstarlet-1.6.1-win32.zip/download"
#     echo "Remember to add the xmlstarlet directory to your PATH environment variable, if you are on Windows!"
#     echo "Press Control + C to escape this program. Left alone, it will close in 60 seconds."
#     sleep 60
#     exit 1
# fi
#     if [[ $PWD == *"test1" ]] && [ $(ls | grep "$templatefilename") == "$templatefilename" ]; then
#         templatefile="./$templatefilename"
#     elif [[ $PWD == *"people" ]]; then
#         templatefile="../$templatefilename"
#     else
#         echo "I haven't a clue what's going on. Good luck."
#         exit 1
#     fi
#
#     if [ -f $newfile ]; then
#         echo -n "File already exists!"
#         echo " Choose another name. Aborting..." && exit 1
#     fi
#
#     if ( command -v xmlstarlet >/dev/null 2>&1 ); then
#         xmlstarlet edit -N s=http://www.tei-c.org/ns/1.0 --update "//s:listPerson/s:person/@xml:id" --value "$persid" "$newfile" > $tmp && cp $tmp $newfile #xmlstarlet to automatically use the last part of the filename as value for the xml:id attribute
#         xmlstarlet format -s 4 $newfile > $tmp && mv $tmp $newfile
#     else
#         xml edit -N s=http://www.tei-c.org/ns/1.0 --update "//s:listPerson/s:person/@xml:id" --value "$persid" "$newfile" > $tmp && cp $tmp $newfile #xmlstarlet to automatically use the last part of the filename as value for the xml:id attribute
#         xml format -s 4 $newfile > $tmp && mv $tmp $newfile
#     fi
#     rm $newfile # clean-up for testing purposes :D
#     while [ -f $newfile ]; do
#         echo "Attempting to fix filename to not conflict."
#         new=$(($((10#$new))+1)); echo $new
#         if [ $new -le "9" ]; then new="0$new"; fi
#         persid="${persid:0:3}$new"
#         if [[ $PWD == "*test1/people*" ]]; then
#             newfile="./$persid.xml"
#         else
#             newfile="./people/$persid.xml"
#         fi
#     done
# cur=$(ls --ignore=*html ./ | grep "${persid:0:3}..\.xml" | tail -n 1)
# cur=$(ls --ignore=*html ./people/${persid:0:3}*xml | tail -n 1)
