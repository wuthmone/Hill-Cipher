#!/bin/bash

# 2x2 Hill Cipher

function end {
	timeElapsed=$(( $(date +"%s%6N") - $start ))
	if [ $quickMode != "true" ]; then
		echo Output: `num2let R[@]`
		printMatrix R[@]
		echo "Time elapsed: "$timeElapsed" microseconds"
	else
		echo $key $msg `num2let R[@]` $timeElapsed
	fi
	exit 0
}

# Function to print 2xn matrix


function printMatrix {
	declare -a A=("${!1}")
	for ((j=0; j<$rows; j++)); do
		i=$j
		echo -n "|"
		while [ $i -lt ${#A[@]} ]; do
			printf " %2d " ${A[$i]}
			i=$(($i+$rows))
		done
		echo "|"
	done
}

# Letter to Number Translator


function let2num {
	for i in `echo "$1" | tr '[:lower:]' '[:upper:]' | grep -o . ` ; do
		echo $((`printf '%d' "'$i"` -65))
	done
}

# Number to Letter Translator


function num2let {
	declare -a A=("${!1}")
	for i in ${A[@]}; do
		echo -n ${letters[$i]}
	done
}

# Modulus Correction Function


function mod {
	echo $(((( $1 % $2 ) + $2 ) % $2 ))
}

# 2x2 Matrix Inverse


function matrixInverse {
	#Evaluating the determinant

	#          |         |             |             |
	#          |  A   C  |             |  K[0]  K[2] |
	# det K =  |         | = AD - BC = |             |
	#          |  B   D  |             |  K[1]  K[3] |
	#          |         |             |             |


	det=`mod $(( ${K[0]} * ${K[3]} - ${K[1]} * ${K[2]} )) 26`
	if [ $quickMode != "true" ]; then
		echo 1/det = 1/$det
	fi

	if [[ $(( $det % 2 )) == 0 || $(( $det % 13 )) == 0 ]]
	then
		echo "Decryption not possible"
		exit 1
	fi
	
	#Finding   1/$det mod 26 = x
	#Therefore $det * x = 1 mod 26
	
	rem=0
	x=-1

	while [ $rem != 1 ] ; do
		x=$(($x+2))
		rem=$(( $(( $det * $x )) % 26 ))
	done

	#				    ^
	#                                   |
	#                                   |
	#                              Always +ve
	if [ $quickMode != "true" ]; then
		echo 1/$det mod 26 = $x
	fi
	##### K = ( ${K[3]} -${K[1]} -${K[2]} ${K[0]} )

	K=( `mod $(( ${K[3]} * $x )) 26` `mod $(( -${K[1]} * $x )) 26` `mod $(( -${K[2]} * $x )) 26` `mod $(( ${K[0]} * $x )) 26` )

}

# Matrix Product

function matrixProduct {
	cols=$(( ${#M[@]} / $rows ))
	for ((col=0; col<$cols; col++)); do
	    for ((row=0; row<$rows; row++)); do
	 
		# Evaluating element R[$row, $col]
		runningTotal=0
		
		# For every j until j = columns of K
		# Columns of K = Rows of K (Square matrix)
		for ((j=0; j<$rows; j++)); do
		    indexK=$(($j*$rows+$row))
		    indexM=$(($rows*$col+j))
		    ((runningTotal+=$((K[$indexK] * M[$indexM]))))
		done
	 
		# Storing the running total in the output
		index=$(($rows*$col+$row))
		R[$index]=`mod $runningTotal 26`
	    done
	done
}

####### Start of Program #######

quickMode=false

# Parameter Check

if [ $# == 0 ]; then
	# Menu mode
	
	
	echo "Please select mode"
	select choice in "Encryption" "Decryption" "Exit"; do
		case $choice in
			"Encryption")
				mode="enc"; break;;
			"Decryption")
				mode="dec"; break;;
			"Exit")
				exit 0;;
			*)
				echo "Invalid option"; exit 0;;
		esac
	done

	echo "Please enter the 4-letter key"
	read key
	key=`echo $key | tr -cd '[:alpha:]' | tr '[:lower:]' '[:upper:]'`
	if [ ${#key} != 4 ]; then
		echo "Invalid key length. Must be 4 letters long."
		exit 1
	fi

	echo "Please enter the message"
	read msg
	msg=`echo $msg | tr -cd '[:alpha:]' | tr '[:lower:]' '[:upper:]'`
	if [ ${#msg} -lt 1 ]; then
		echo "Message is empty."
		exit 1
	fi
elif [[ ($# == 3) || ($# == 4 && $4 == "quick") ]]; then
	# Parameter mode
	

	mode=`echo $1 | tr '[:upper:]' '[:lower:]'`
	key=`echo $2 | tr -cd '[:alpha:]' | tr '[:lower:]' '[:upper:]'`
	msg=`echo $3 | tr -cd '[:alpha:]' | tr '[:lower:]' '[:upper:]'`
	if [[ $mode != "enc" && $mode != "dec" ]]; then
		echo "Invalid mode. Type enc or dec."
		exit 1
	fi
	if [ ${#key} != 4 ]; then
		echo "Invalid key length. Must be 4 letters long."
		exit 1
	fi
	if [ ${#msg} -lt 1 ]; then
		echo "Message is empty."
		exit 1
	fi
	if [ $# == 4 ]; then
		quickMode=true
	else
		quickMode=false
	fi
else
	# Failed to fulfil parameter requirements
	echo "Usage: <[enc|dec]> <4-letter key> <message> [quick]"
	exit 1
fi

# Letter array
letters=( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )

# Converting key and message into arrays of integers
K=(`let2num "$key"`)
M=(`let2num "$msg"`)
rows=2;

#Check if the length of the message fills the matrix. If not, append a filter.
while [ $(( ${#M[@]} % $rows )) != 0 ]; do
	#Filter = X; X = 23
	M+=(23)
done

if [ $quickMode != true ]; then
	echo "Key: "`num2let K[@]`
	printMatrix K[@]
	echo
	
	if [ $mode == "dec" ]; then
		echo -n "Ciphertext"
	else
		echo -n "Plaintext"
	fi
	echo ": "`num2let M[@]`
	printMatrix M[@]
	echo
fi
# Get start time in microseconds
start=$(date +"%s%6N")
if [ $mode == "dec" ]; then
	#Decryption by matrix inverse of key, then matrix product
	#P = K^-1 * C
	if [ $quickMode != "true" ]; then
		echo "Decrypting..."
	fi
	matrixInverse
	if [ $quickMode != "true" ]; then
		echo
		echo "Inverse key: "`num2let K[@]`
		printMatrix K[@]
		echo
	fi
else
	#Encryption by matrix product only
	#C = KP
	if [ $quickMode != "true" ]; then
		echo "Encrypting..."
		echo
	fi
fi

R=( )
#Shared matrix product function
matrixProduct
end
