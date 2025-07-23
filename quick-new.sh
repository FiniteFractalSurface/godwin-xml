#!/bin/bash
cd "`dirname "$0"`"
# Dependency check: xmlstarlet; below works maybe

# if ( ! type "xmlstarlet" > /dev/null ) && ( ! type "xml" > /dev/null ) ; then
if ( command -v xmlstarlet >/dev/null 2>&1 ) && ( command -v xml >/dev/null 2>&1 ); then
    echo -e "You don't have xmlstarlet installed. This is a required dependency for this script.\nPlease go here to install xmlstarlet: https://sourceforge.net/projects/xmlstar/files/xmlstarlet/1.6.1/xmlstarlet-1.6.1-win32.zip/download"
    echo "Remember to add the xmlstarlet directory to your PATH environment variable, if you are on Windows!"
    echo "Press Control + C to escape this program. Left alone, it will close in 60 seconds."
    sleep 60
    exit 1
fi

templatefilename="AApersonTemplate.xml"

if [ "$1" == "" ]; then
    clistart=0
    echo -n "Enter full path of new file: "; read name
    work="$name"

    #if [ "$name" == ] #name variable validation
else
    clistart=1
    work="$1"
fi



if [[ $PWD != *"test1" ]] && [[ $PWD != *"people" ]]; then #TODO I think the conditions here are wonk
    echo "You're not in the right directory. Please change directory to either test1 or people."
fi

if [ -f ../$templatefilename ] || [ -f ./$templatefilename ] || [ -f ./people/$templatefilename ]; then

    templatefile=$(find -type f -path "*/$templatefilename" -prune)

    echo "You're probably in the right directory, and the template file is probably available."
    echo -ne "Template file in use: \033[1;35m$templatefile\033[0m. "

    # TODO: More leeway with input: Either ask for only 5 char code or the last name of the person concerned
    echo ""

    if [[ "$PWD" == *"test1" ]] && [[ "$work" == ????? ]] && [[ "$work" != ?????".xml" ]]; then
        persid="$work"
        newfile="./people/$work.xml"
    elif [[ "$PWD" == *"people" ]] && [[ "$work" == ????? ]] && [[ "$work" != ?????".xml" ]]; then
        newfile="./$work.xml" # this is like this because ideally you would use the shell's autocomplete function to check if a name is taken, and thus write ./people/XXX99.xml if you're in test1/ or ./XXX99.xml if you're in people/
    else
        echo "Try running it from the terminal instead of directly."
        exit 1
    fi



    if [[ ${newfile: -4} == ".xml" ]]; then
        echo -n "Filename extension seems right! "
    else
        echo -n "Filename extension lacks .xml, adding... "
        newfile="$newfile.xml"
    fi

    persid=${newfile%.xml} && persid=${persid##*/} # extracts the code id from the filename, since they are one in the same.
    echo -e "Current person ID value: \033[0;32m$persid\033[0m."

    echo -n "Checking filename validity" && for ((n=0;n<3;n++)); do sleep 0.2 && echo -n "."; done; echo -e " " # Literally cosmetic and pointless, but it looks cool though.

    if [[ ${newfile: -9} == ?????".xml" ]] && [ "${persid: -2}" -le "99" ] && [ "${persid: -2}" -ge "0" ]; then # Checks if filename has exactly 5 characters then checks if the last two characters are numbers between 0-99
        echo "Filename seems to follow the 5 char convention!"
    else
        echo "That name doesn't quite seem right. Try again?"
        exit 1
    fi

#     if [ -f $newfile ]; then
#         echo -n "File already exists!"
#         echo " Choose another name. Aborting..." && exit 1
#     fi

    new=${persid: -2}

    if [ -f $newfile ]; then
        echo -ne "\033[0;31mFile already exists\!\033[0m "
        echo -n "Attempting to fix filename to not conflict. "
        if [[ "$PWD" == *"test1" ]]; then
            cur=$(ls ./people | grep "${persid:0:3}..\.xml" | tail -n 1)
        elif [[ "$PWD" == *"test1/people" ]]; then
            cur=$(ls ./ | grep "${persid:0:3}..\.xml" | tail -n 1)
        else
            echo "You're in the wrong directory. How is that possible? We checked above!"
        fi

        cur=${cur%.xml} && cur=${cur##*/}; cur=${cur: -2}; cur=$((10#0$cur)) # grabs current
        new=$((10#$(($new+$(($cur-$new))+1))))

        if [ $new -le "9" ]; then new="0$new"; fi
        persid="${persid:0:3}$new"
        if [[ "$PWD" == "*test1/people*" ]]; then
            newfile="./$persid.xml"
        else
            newfile="./people/$persid.xml"
        fi
        echo -e "New person ID: \033[0;32m$persid\033[0m."
    fi

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

    echo -e "Creating \033[0;32m$newfile\033[0m."
    cp --no-clobber $templatefile $newfile || echo "Something is still wrong."

    tmp="./.tmp.xml"
    echo "Echoing in person ID and formatting XML file using xmlstarlet."
    sed -i "s/xml:id=\"XXX99\"/xml:id=\"$persid\"/g" $newfile
    if [ ! "$2" == "" ]; then sed -i "s/sex=\"1\"/sex=\"$2\"/g" $newfile; fi

#     if ( command -v xmlstarlet >/dev/null 2>&1 ); then
#         xmlstarlet edit -N s=http://www.tei-c.org/ns/1.0 --update "//s:listPerson/s:person/@xml:id" --value "$persid" "$newfile" > $tmp && cp $tmp $newfile #xmlstarlet to automatically use the last part of the filename as value for the xml:id attribute
#         xmlstarlet format -s 4 $newfile > $tmp && mv $tmp $newfile
#     else
#         xml edit -N s=http://www.tei-c.org/ns/1.0 --update "//s:listPerson/s:person/@xml:id" --value "$persid" "$newfile" > $tmp && cp $tmp $newfile #xmlstarlet to automatically use the last part of the filename as value for the xml:id attribute
#         xml format -s 4 $newfile > $tmp && mv $tmp $newfile
#     fi
    #rm $newfile # clean-up for testing purposes :D

else
    echo "Template file not found! Check your current working directory."
    exit 1
fi

if [ $clistart == 0 ]; then echo "Script will close in 10 seconds. To close immediately, press Control + C. To keep output press Control + S."; sleep 10; fi

# Archived code that exists for no particular reason
#     if [[ $PWD == *"test1" ]] && [ $(ls | grep "$templatefilename") == "$templatefilename" ]; then
#         templatefile="./$templatefilename"
#     elif [[ $PWD == *"people" ]]; then
#         templatefile="../$templatefilename"
#     else
#         echo "I haven't a clue what's going on. Good luck."
#         exit 1
#     fi
#
#
