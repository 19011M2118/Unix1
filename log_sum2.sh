#Block of code sets the filename to the last argument, or pipes the input of the file to this script
if [ -p /dev/stdin ]; then
for file in ./thttpd.log; do echo " " ; done
thttpd="$file"
else
thttpd="${!#}"
fi

#Using getopts for handling the arguments
while getopts ":L:c2rFtez" opt; do
  case $opt in 
#--------------------------------------------------------------------------------------------------	
	L)
	#When there is a limit argument, push it into the Limit variable
  	Limit="$OPTARG">&2
       ;;
     
#-------------------------------------------------------------------------------------------------       
	
	c)
	#IP that makes the most number of connection attempts
	#-z means if there is no limit
	if [ -z "$Limit" ];
	then
	#Regular expression for IP, sort, and then count
	#I could have also used cut but I wanted to get familiar with regular expressions
	#Cut would have looked like this cut -d " " -f 1 thttpd.log|sort|uniq -c|sort -nr|head -n 10|awk '{print $1"  "$2}'
	grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $thttpd |sort|uniq -c|sort -nr| awk '{print $2"\t"$1}'
	else
	grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $thttpd |sort -nr|uniq -c|sort -nr|head -n $Limit| awk '{print $2"\t"$1}'
	fi
checkc="checkc"
       ;;
#-------------------------------------------------------------------------------------------------
       
        2)
       	#IP that makes the most number of connection attempts
       	successful_connection=200
	if [ -z "$Limit" ];
	then
	#Regular expression for IP, although the results where 200 also doesn't transfer bytes are included?
	grep "${successful_connection}\ [0-9]\{1,5\}" $thttpd|sort -n -k1|awk '{print $1"  "$9"  "$10}'|cut -d " " -f 1| sort| uniq -c |sort -nr|awk '{print $2"\t"$1"\t"$9 }'
	else
	grep "${successful_connection}\ [0-9]\{1,5\}" $thttpd|sort -n -k1|awk '{print $1"  "$9"  "$10}'|cut -d " " -f 1| sort| uniq -c |sort -nr|head -n $Limit|awk '{print $2"\t"$1"\t"$9 }'
	fi
check2="check2"
       ;;
 #--------------------------------------------------------------------------------------------------      
       
        r)
        #set -- $(cut -d " " -f 9 $thttpd | sort| uniq -c |sort -nr|awk '{print $2}')
        #Uncomment this above command to get the order of the result codes, didn't use a for loop for this script to make things simple, make this a for loop if there are many result codes
	#Ignore the above comment
	declare indexed_array
	i=0
	while read a; do
	indexed_array[i]="$a"
	i=$((i+1))
	done < <(cut -d " " -f 9 thttpd.log | sort| uniq -c |sort -nr|awk '{print $2}')
	checkr2="checkr"
	#The most common result codes
        if [ -z "$Limit" ];
        then
	for i in 0 1 2 3 4 5
		do
		grep "${indexed_array[$i]}\ [0-9]\{1,5\}\| ${indexed_array[$i]}\ - " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|awk '{print $3"\t"$2"\t"}'
		echo " "
	done
	else
	for i in 0 1 2 3 4 5
	do
		grep "${indexed_array[$i]}\ [0-9]\{1,5\}\| ${indexed_array[$i]}\ - " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|head -n $Limit|awk '{print $3"\t"$2"\t"}' 
		echo " "
		done    
	fi
	;;  
#--------------------------------------------------------------------------------------------------	
	F)
	#Most common result codes that indicate failure

	#set -- $(cut -d " " -f 9 $thttpd | sort| uniq -c |sort -nr|awk '{print $2}')
	declare indexed_array
	i=0
	while read a; do
	indexed_array[i]="$a"
	i=$((i+1))
	done < <(cut -d " " -f 9 thttpd.log | sort| uniq -c |sort -nr|awk '{print $2}')
	declare faulty_indexed_array
	checkf="checkf"
	for i in 0 1 2 3 4 5
	do
	if [[ ${indexed_array[$i]} == 404 || ${indexed_array[$i]} == 401 || ${indexed_array[$i]} == 403 ]]
	then
	faulty_indexed_array[i]=${indexed_array[$i]}
	fi
	done
	if [ -z "$Limit" ];
        then
	for i in 0 1 2 4
		do
		grep " ${faulty_indexed_array[$i]}\ - " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|awk '{print $3"\t"$2"\t"}'
		echo " "
	done
	else
	for i in 0 1 2 4
	do
		grep " ${faulty_indexed_array[$i]}\ - " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|head -n $Limit|awk '{print $3"\t"$2"\t"}' 
		echo " "
		done    
	fi
	;;  
#--------------------------------------------------------------------------------------------------------	
	
	t)
	checkt="checkt"
	if [ -z "$Limit" ]; #1 Outermost layer
	then
		cut -d " " -f1-1,10-10 $thttpd|sort>newthttpd.log
		sed -i 's/-/0/g' newthttpd.log
		previous_ip=0 ; sum=0 ;
		printf '%s\n' "${b}"
		while read a b ; do \
  			if [ "$a" == "$previous_ip" ] ; then \
    				sum=$(($sum+$b)) ; 
   			else 
    				if [ "$previous_ip" != 0 ] ; then \
      				echo $previous_ip $sum ; 
    				fi ; 
    			previous_ip=$a ; sum=$b ; 
  			fi ; 
		done < <(cat newthttpd.log | awk -F' ' '{printf("%s %s\n",$1,$2)}' | sort -n)>newestbytes.txt 
		
		cut -d " " -f1-1,2-2 newestbytes.txt|sort -n -r -k 2,2

	else #1 Outermost layer
		cut -d " " -f1-1,10-10 $thttpd|sort>newthttpd.log
		sed -i 's/-/0/g' newthttpd.log
#https://unix.stackexchange.com/questions/512250/how-to-grep-and-cut-numbers-from-a-file-and-sum-them
#got this idea from here
		previous_ip=0 ; sum=0 ;
		printf '%s\n' "${b}"
		while read a b ; do \
			if [ "$a" == "$previous_ip" ] ; then \
			    	sum=$(($sum+$b)) ; 
			else 
			    if [ "$previous_ip" != 0 ] ; then \
			      echo $previous_ip $sum ; 
			    fi ; 
    			previous_ip=$a ; sum=$b ; 
  			fi ; 
		done < <(cat newthttpd.log | awk -F' ' '{printf("%s %s\n",$1,$2)}' | sort -n)>newestbytes.txt 
		cut -d " " -f1-1,2-2 newestbytes.txt|sort -n -r -k 2,2|head -n $Limit
	fi #1 Outermost layer
;;
#---------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------
	e)
	ip=$(dig +short $(cat dns.blacklist.txt))
	blacklisted_ip=$(grep -o "${ip}" thttpd.log|sort|uniq -c|awk '{print $2}')
	successful_connection=200
	declare indexed_array
	i=0
	while read a; do
	indexed_array[i]="$a"
	i=$((i+1))
	done < <(cut -d " " -f 9 thttpd.log | sort| uniq -c |sort -nr|awk '{print $2}')
	declare faulty_indexed_array
	#for i in 0 1 2 3 4 5
	#do
	#if [[ ${indexed_array[$i]} == 404 || ${indexed_array[$i]} == 401 || ${indexed_array[$i]} == 403 ]]
	#then
	#echo "$i"
	#faulty_indexed_array[i]=${indexed_array[$i]}
	#fi
	#done
	#this above part interferes with out optind variable for some reason
	#run this above part to get the order of the fault codes 404 most frequent...
	faulty_indexed_array[0]=${indexed_array[0]}
	faulty_indexed_array[1]=${indexed_array[2]}
	faulty_indexed_array[2]=${indexed_array[4]}
	echo ""
	echo "Blacklisted part "
	echo ""
	
#1 is the outermost layer to check whether or not there is a limit
#2 is the inner layer to check which argument is passed, since -e should work with every argument
#probably not the best way to do this but couldn't think of anything else
if [ -z "$Limit" ];
#1 if there is no limit 
then
	
	
	
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
		if [ -n "$checkc" ]; #check for c #2
		then
			while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $thttpd |sort|uniq -c|sort -nr| awk '{print $2"\t"$1}')
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
		elif [ -n "$check2" ]; #check for 2 #2
		then
		echo "Ideally there shouldn't be any blacklisted ip's here"
			while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(grep "${successful_connection}\ [0-9]\{1,5\}" $thttpd|sort -n -k1|awk '{print $1"  "$9"  "$10}'|cut -d " " -f 1| sort| uniq -c |sort -nr|awk '{print $2"\t"$1"\t"$9 }')
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------			
		elif [ -n "$checkr2" ]; #2
		then
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(for i in 0 1 2 3 4 5
		do
		grep "${indexed_array[$i]}\ [0-9]\{1,5\}\| ${indexed_array[$i]}\ - " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|awk '{print $2" "$3}'
		echo " "
	done)	
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
		elif [ -n "$checkf" ]; #2
		then
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(
			for i in 0 1 2
		do
		grep " ${faulty_indexed_array[$i]}\ - " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|awk '{print $2" "$3}'
		echo " "
	done
			)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------			
		elif [ -n "$checkt" ]; #2
		then
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(cut -d " " -f1-1,2-2 newestbytes.txt|sort -n -r -k 2,2|awk '{print $1"\t"$2'})
		fi
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	else #THIS IS THE MAIN IF-ELSE FOR THE LIMIT #1
		if [ -n "$checkc" ]; #check for c #2
		then
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi;
			done < <(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $thttpd |sort|uniq -c|sort -nr|head -n $Limit| awk '{print $2"\t"$1}')
			
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------			
		elif [ -n "$check2" ]; #2
		then
		echo "Ideally there shouldn't be any blacklisted ip's here"
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(grep "${successful_connection}\ [0-9]\{1,5\}" $thttpd|sort -n -k1|awk '{print $1"  "$9"  "$10}'|cut -d " " -f 1| sort| uniq -c |sort -nr|head -n $Limit|awk '{print $2"\t"$1"\t"$9 }')
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------			
		elif [ -n "$checkr2" ]; #2
		then
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(
for i in 0 1 2 3 4 5
	do
		grep "${indexed_array[$i]}\ [0-9]\{1,5\}\| ${indexed_array[$i]}\ - " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|head -n $Limit|awk '{print $2" "$3}' 
		echo " "
		done 
)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
		elif [ -n "$checkf" ]; #2
		then
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(
			for i in 0 1 2
		do
		grep " ${faulty_indexed_array[$i]} " $thttpd|cut -d " " -f1-1,9-9| sort| uniq -c |sort -nr|head -n $Limit|awk '{print $2" "$3}'
		echo " "
	done
			)
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				
		elif [ -n "$checkt" ]; #2
		then
		while read a b ; do
			if [ "$blacklisted_ip" = "$a" ]
			then
			echo $a"     "$b"     Blacklisted"
			else
			echo $a"     "$b
			fi
			done < <(cut -d " " -f1-1,2-2 newestbytes.txt|sort -n -r -k 2,2|head -n $Limit|awk '{print $1"\t"$2'})
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
		fi #2
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
	fi #1
	;;
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	*)
       echo "invalid command"
       ;;
  esac
done




