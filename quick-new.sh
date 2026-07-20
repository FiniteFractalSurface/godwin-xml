#!/bin/sh
# This script aims to
#   (1) speed up the process of creating new person files
#   (2) ensure the structure of new are consistent with the template
#   (3) ensure naming convention is followed

# Function defined start
setnewfiledir () { # this makes it so that the script works in both the outside directory and inside /people
    if ( echo "$PWD" | grep -Eq "$repoName$" ); then newfile="./people/$work"
    elif ( echo "$PWD" |  grep -Eq 'people$' ); then newfile="./$work"
    fi
}
fancyelip () {
    elipdelay="0.1" # default value
    if ( echo "$1" | grep -Eq '^[0-9]+$' ); then
        elipdelay="$1"
    elif echo "$2" | grep -Eq '^[0-9]+$'; then
        elipdelay="$2"
    fi
    n=0; while [ "$n" -lt 3 ]; do sleep "$elipdelay" && printf "."; n=$((n+1)); done; printf " "
    if [ "$1" = "--newline" ]; then printf "\n"; fi
}
slowexit () {
    sleep 10
    exit 1
}
# Function defined end

# Variable declarations start
templatefilename="AApersonTemplate.xml"
repoName=$(basename "$(git rev-parse --show-toplevel)")
# repo="godwin-xml" # TODO unused variable, maybe in the future
# Variable declarations end

cd "$(dirname "$0")" || slowexit # For the sake of double-click run

if uname -s | grep -q "Darwin"; then echo "Current operating system is OSX. This script is completely untested on OSX and you may encounter wild and fantastical errors. Proceed at your own risk."; fi

if ( echo "$PWD" | grep -q ".*$repoName$" ) && ( echo "$PWD" | grep -q '.*people$' ); then # Error condition 1: Is the working directory correct? Valid working directories are godwin-xml or people
    echo "You're not in the right directory. Please change directory to either godwin-xml or people."
    slowexit
fi

# This is quite fragile since there is no error handling. If $templatefilename is not set precisely then... well all bets are off.
if [ ! -f ../$templatefilename ] && [ ! -f ./$templatefilename ] && [ ! -f ./people/$templatefilename ]; then # Error condition 2: Is the template file, as defined at the beginning, available?
    echo "Template file not found! Check your current working directory."
    slowexit
fi
# TODO Make independent fallback template, hard-coded into the script using printf

if [ "$1" = "" ]; then
    clistart=0
#     printf "Welcome to the quick new script, ver. 1.0!\nThis script is used to speed up the creation process of new person files."
    printf "Enter person ID (e.g. ABC01): "; read -r nameorid # ID or three letters or full path, quod libet
    work="$nameorid"
else
    clistart=1
    work="$1"
    if [ "$1" = "--version" ]; then echo "1.0.0"; fi
fi

templatefile=$(find . -type f -path "*/$templatefilename" -prune) # TODO this assumes only one templatefile with the templatefilename... That's gotta be solved somehow
printf "Template file in use: \033[1;35m%s\033[0m.\n" "$templatefile"

if ( echo "$work" | grep -Eq '^[A-Z]{3}[0-9]{2}$' ); then # checks input to see if it's a persid. three letters only, or full path
    setnewfiledir
    newfile="$newfile"".xml"
    persid="$work"
elif ( echo "$work" | grep -Eq '^[A-Z]{3}$' ); then
    setnewfiledir
    newfile="$newfile""01.xml"
    persid="$work""01"
elif ( echo "$work" | grep -Eq '^[A-Z]{3}[0-9]{2}\.xml$' ); then # this is for input that's a persid + .xml extension
    setnewfiledir
    persid=${newfile%.xml} && persid=${persid##*/}
elif ( echo "$PWD" | grep -Eq 'people$' ) || ( echo "$PWD" | grep -Eq "$repoName" ); then # below is for backwards compatibility with primitive workflow that deals with raw file paths; kinda bork
    newfile="$work"
    persid=${newfile%.xml} && persid=${persid##*/} # extracts the code id from the filename, since they are one in the same.
else
    echo "Something's wrong."
    slowexit
fi

if ( echo "$newfile" | grep -Eq '\.xml$' ); then
    printf "Filename extension seems right! "
else
    printf "Filename extension lacks .xml, adding... "
    newfile="$newfile"".xml"
fi

printf "Current person ID value: \033[0;32m%s\033[0m.\nChecking filename validity" "$persid" && fancyelip # Literally cosmetic and pointless, but it looks cool though.

if ( echo "$newfile" | grep -Eq '^.*\/[A-Z]{3}[0-9]{2}\.xml$' ); then # the .*\/ is to ensure the file is being written to the right dir
    echo "Filename seems to follow the 5 char convention!"
else
    echo "That name doesn't quite seem right. Please try again with just the person code without the file extension. For example, SMI02."
    slowexit
fi

if [ -f "$newfile" ]; then
    new=$(echo "$persid" | grep -Eo '[0-9]{2}$') # basically only exists so the failure scenario can take place

    printf "\033[1;33mFile already exists\033[0m! Attempting to fix filename to not conflict. "
    if echo "$PWD" | grep -Eq "$repoName$" ; then
        if [ ! "$(uname -o)" = "GNU/Linux" ]; then echo "If you're stuck on this, please be patient and let it run its course. This can occur the first time the script used after starting the operating system."; fi
        switch2="people/"
    elif echo "$PWD" | grep -Eq 'people$' ; then
        switch2=""
    else echo "You're in the wrong directory. How is that possible? We checked above!"; exit 1
    fi

    # TODO make it detect gaps and fill those, by detecting the number of files, comparing that with the highest number, and then initiating a scan for the gap from the bottom up

    cur=$(find ./$switch2 -maxdepth 1 -path "*""$(echo "$persid" | grep -Eo '^[A-Z]{3}')""*xml" | sort | tail -n 1 | sed -n 's/.*[A-Z]\{3\}\([0-9]\{2\}\)\.xml$/\1/p' | sed "s/^0//") # I'm doing this horribleness because Msys doesn't want to play ball with the bc command and if I don't then it gets interpreted as octal and can't be incremented
    new=$((cur+1)) # increments by one

    if [ $new -le 9 ]; then new="0""$new"; fi # takes the raw number and turn it into a string
    persid="$(echo "$persid" | grep -Eo '^[A-Z]{3}')""$new"

    if echo "$PWD" | grep -Eq 'people$' ; then
        newfile="./$persid.xml"
    else newfile="./people/$persid.xml"
    fi

    printf "New person ID: \033[0;32m%s\033[0m.\n" "$persid"
    if [ -f "$newfile" ]; then echo "We've failed." && slowexit; fi
fi
#TODO check if there's a corresponding html file. If there is, ask to make certain that overwriting ghost file is intended. The reason why this is out here instead of in the above check is so that this check is certain to happen, regardless if there was a filename collision.
# if [ -f "$persid"".html" ]; then
#     printf "The newly created file will use the code of a ghost file. Is this what you want to do? (y/N): "; read -r yn
#     if
#     newfile=""
# fi


#
#
# Error checking and prelude done, actual XML field work starts here
#

printf "Creating \033[0;32m%s\033[0m.\n" "$newfile"

cp --no-clobber "$templatefile" "$newfile" || echo "Something is still wrong."

echo "Writing in person ID and formatting XML file with sed."

sed -i "s/xml:id=\"XXX[0-9]\{2\}\"/xml:id=\"$persid\"/g" "$newfile"

( echo "$2" | grep -Eq '^[12]' ) && sed -i "s/sex=\"1\"/sex=\"$2\"/g" "$newfile"

encoderinitials="$(git config --get user.name | sed -n 's/^\([A-Z]\).*\([A-Z]\).*$/\1\2/p')" # Gets initial
sed -i "s/<name>ENCODER<\/name>/<name>$encoderinitials<\/name>/g" "$newfile" # Writes to file with initials

if [ "$(uname -o)" = "GNU/Linux" ] && ( command -v kate >/dev/null 2>&1 ); then # this is my personal thing, don't worry about it!
    echo "Opening with kate." && kate "$newfile"
elif [ "$(uname -o)" = "Msys" ]; then # automatically opens up Oxygen for editing. A bit slow but that's on the part of Oxygen.
    oxxmlloc="/c/Program Files/Oxygen XML Editor 28/oxygen.bat"
    if [ -f "$oxxmlloc" ]; then
        "$oxxmlloc" file:"$newfile" 2>/dev/null &
        printf "Found Oxygen XML Editor. Opening now. Please wait a few seconds" && fancyelip --newline "0.3"
    elif [ ! -f "$oxxmlloc" ]; then
        echo "Did not find Oxygen XML Editor at expected location. Trying again..."
        curveball="$(find "/c/Program Files/" -maxdepth 2 -path "*oxygen.bat" 2>/dev/null)"
        [ ! "$curveball" = "" ] && ( "$curveball" file:"$newfile" 2>/dev/null & )
    fi
# else
#     echo "I don't know what OS you're running. So I'm just going to try to open a text editor. Good luck."
#     editor "$newfile" || nano "$newfile"
fi

if [ $clistart = 0 ]; then
    echo "Script will close in 10 seconds. To close immediately, press Control + C."
    sleep 10
fi

exit 0
