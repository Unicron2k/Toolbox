#!/bin/bash

function get_img_url() {
	IMAGE_PAGE_URL="${NEXT_EPISODE_URL/post/'image'}";
	wget -q $IMAGE_PAGE_URL -O temp2.html;
	IMG_URL=$( grep -P -o 'https://64.media.tumblr.com/.*?.jpg' temp2.html | tail -1 );
	if $VERBOSE
	then
        printf "Image URL: $IMG_URL\n";
    fi;
}
function get_next_episode_url() {
	NEXT_EPISODE_URL=$( grep -Po '(?<=<a href=")http://chiefobrienatwork.com/post/.*(?=">Read the next episode)' temp.html );
	if $VERBOSE
	then
        printf "\nNext episode URL: $NEXT_EPISODE_URL\n";
    fi;
}
function get_episode_name {
	EPISODE_NAME=$( grep -Po '(?<="articleBody":").*?(?=\\nRead the (next|new) episode)' temp.html | tail -1 );
	EPISODE_NAME=${EPISODE_NAME// /_};
	EPISODE_NAME=$(echo "$EPISODE_NAME" | tr '[:upper:]' '[:lower:]');
	if $VERBOSE
	then
        printf "Episode name: $EPISODE_NAME\n";
    fi;
}

### Hacky mcHack
function fix_broken_stuff(){
    # Fix broken names
    # TODO: Improve regex-matching
    mv "chief_o'brien_at_work_-_check_out_the_cartoon_and_the_kickstarter!\nepisode_89:_answering_machine.jpg" "chief_o'brien_at_work_-_episode_89:_answering_machine.jpg";
}


### Process arguments "$1", "$2", ... (i.e. "$@")
while getopts "vhO:F" opt; do
    case $opt in
    v)  # Display debug data
        VERBOSE=true ;;
    
    h)  # Display usage
        # TODO: Implement this
        echo "Usage: TBD...";
        exit ;;
        
    O)  # Specify alternate output directory
        # TODO: Implement this
        if [ -d $OPTARG ]
        then 
            OUTPUT_DIR=$OPTARG;
        else
            OUTPUT_DIR=$PWD;
        fi;;
    
    F)  # Force re-download of all files
        # TODO: Implement this
        echo "Force redownload not yet implemented...\n";;
        
    \?) # Handle errors
        echo "Unknown option or missing a required argument.";
        exit;;
    esac
done

### Setup some stuff ###
mkdir "$HOME/Desktop/Chief O'Brien at Work";
cd "$HOME/Desktop/Chief O'Brien at Work";
touch episodes.txt
NEXT_EPISODE_URL="https://chiefobrienatwork.com/post/106684455801/";
wget -q $NEXT_EPISODE_URL -O temp.html;

### Main Loop ###
while [[ -z $NEXT_EPISODE_URL ]]
	
	get_episode_name;
	
	get_img_url;
	
	echo "$EPISODE_NAME - $NEXT_EPISODE_URL - $IMAGE_PAGE_URL - $IMG_URL" >> episodes.txt
	printf "Fetching 'chief_o'brien_at_work_-_$EPISODE_NAME'";
	wget -q $IMG_URL -O "chief_o'brien_at_work_-_$EPISODE_NAME.jpg";
	if [ -e "chief_o'brien_at_work_-_$EPISODE_NAME.jpg" ]
	then
        echo " - Done";
	else
        echo " - Failed!";
    fi
    
	get_next_episode_url;
	wget -q $NEXT_EPISODE_URL -O temp.html;
do true; done

### Cleanup ###
fix_broken_stuff;
rm temp.html;
rm temp2.html;
rm nul;
#clear;
read -n 1 -s -r -p "Cheif O'Brien has reported to your desktop...";
