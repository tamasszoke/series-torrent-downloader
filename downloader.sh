#!/bin/bash

# variables
search="walking dead"

# install ktorrent if neccessary
if ! which ktorrent >/dev/null; then
	
	echo
	echo "Installing ktorrent..." # better for eyes
	{
		sudo apt-get install -y ktorrent

	} &> /dev/null # this need for silent installation (function output to null)

	echo "Ktorrent installed!" # better for eyes

	# assume its the first run so ask user if run at startup

	echo
	read -p "Always run at startup? [Y/n] " answer # read user input to 'answer' variable

	# ${#answer} means length of answer, if 0 then 'enter key' pressed
	if [ ${#answer} -eq 0 ] || [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then

		path=$(echo "$(dirname $(readlink -f $0))/`basename $0`") # get full path of this script
		name=$(echo "$0") # get name of this script

		# create .desktop file for 'startup applications'
		echo '[Desktop Entry]
		Type=Application
		Exec='$path'
		Hidden=false
		NoDisplay=false
		X-GNOME-Autostart-enabled=true
		Name[en_IN]='$name'
		Name='$name'
		Comment[en_IN]=
		Comment=' > ~/.config/autostart/$name.desktop

		echo "Running at startup!"
		echo "(To disable go to 'Startup applications' in launcher.)"

	else

		echo "Not running on startup!"
	fi
fi

# create downloaded.txt if neccessary
if [ ! -f downloaded.txt ]; then

	> downloaded.txt # create command
fi

# get downloaded names as array from downloaded.txt
IFS=$'\n' read -d '' -r -a array_downloaded_names < downloaded.txt

# check if array empty, sets variables
if [ ${#array_downloaded_names[@]} -eq 0 ]; then # count elements, if 0 then no elements

	last_downloaded_season=0 # reset value
	last_downloaded_episode=0 # reset value
	
else

	last_downloaded_name="${array_downloaded_names[-1]}" #last element is the newest downloaded, since echo puts to new line to the end of file
	#echo $last_downloaded_name

	last_downloaded_season=$(echo $last_downloaded_name | egrep -o S[0-9]+ | cut -c 2-) # extract 'S' and following numbers till a letter
	last_downloaded_episode=$(echo $last_downloaded_name | egrep -o E[0-9]+ | cut -c 2-) # extract 'E' and following numbers till a letter
fi

#echo $last_downloaded_season
#echo $last_downloaded_episode

echo
echo 'Searching for new "'$search'" episode...' # better for eyes

# get magnet links for 'search' from thepiratebay to an array variable
all_magnet_link=( $(curl -s "https://thepiratebay.org/search/${search}" | grep 'a href="magnet:' | cut -d '"' -f2) )
#echo $all_magnet_link

# process magnet links
for magnet_link in "${all_magnet_link[@]}"
do
	IFS='&' read -r -a array_magnet_link <<< "$magnet_link" # make array from string, separate by '&'
	torrent_name=$(echo "${array_magnet_link[1]}" | cut -c 4-) # start with the 4th character (cut the 'dn=')

	season=$(echo $torrent_name | egrep -o S[0-9]+) # extract 'S' and following numbers till a letter
	episode=$(echo $torrent_name | egrep -o E[0-9]+) # extract 'E' and following numbers till a letter
	#echo $season
	#echo $episode

	season_number=$(echo $season | cut -c 2-) # extract numbers
	episode_number=$(echo $episode | cut -c 2-) # extract numbers
	#echo $season_number
	#echo $episode_number

	char_number=$(echo $torrent_name | grep -b -o $season | cut -c -2) # find char number while reaches $season, to get the title only
	#echo $char_number

	formatted_name=$(echo "$torrent_name" | cut -c -"$char_number") # cut the part before season from 'torrent_name' string
	#echo $formatted_name

	name=$formatted_name$season"."$episode # name separated by '.' (dots)
	#echo $name
	
	if [[ "$season_number" -ge "$last_downloaded_season" ]] && [[ "$episode_number" -gt "$last_downloaded_episode" ]]; then

		echo "New episode found!" $name
		echo
		echo "Starting ktorrent..."

		{
			/usr/bin/ktorrent --silent $magnet_link # start torrent with ktorrent program

		} &> /dev/null # this needs for silent installation (function output to null)

		echo "Downloading $name..."
		notify-send "New episode found" "Downloading "$name

		echo $name >> downloaded.txt # save formatted torrent name to downloaded.txt
		echo
		exit # exit from script
		
	else
	
		echo "No new episode."
		echo
		exit # exit from script
	fi
done
