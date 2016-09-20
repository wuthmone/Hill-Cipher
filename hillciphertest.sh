#!/bin/bash

# Hill Cipher Automated Testing

maxLength=256

attempts=0
failedAttempts=0
now=$(date +"%s")
targetFile="hcresult"$now".txt"
avgFile="hcavg"$now".txt"

echo "CurLen Key Plaintext Ciphertext EncTime Decrypted DecTime" > $targetFile
echo "CurLen AvgEncTime AvgDecTime" > $avgFile

letters=( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )
for ((currentLength=2; currentLength<=maxLength; currentLength+=2)); do
	avgEnc=0
	aveDec=0
	for ((i=0; i<10; i++)); do
		((attempts++))
		key=""
		K=( )
		for j in {1..4}; do
			rand=$RANDOM%26
			K+=( $rand )
			key=$key${letters[$rand]}
		done

		#Determinant check, saves time
		det=$(((((${K[0]}*${K[3]}-${K[1]}*${K[2]})%26)+26)%26))
		if [[ $(($det % 2)) == 0 || $(($det % 13)) == 0 ]]; then
			((failedAttempts++))
			((i--))
			continue
		fi

		msg=""
		for ((j=1; j<=$currentLength; j++)); do
			msg=$msg${letters[$RANDOM%26]}

		done
		
		enc=( `bash hillcipher.sh enc $key $msg quick` )
		dec=( `bash hillcipher.sh dec $key ${enc[2]} quick` )
		
		echo $currentLength ${enc[3]} ${dec[3]}
		echo $currentLength ${enc[@]} ${dec[2]} ${dec[3]} >> $targetFile
		
		((avgEnc+=${enc[3]}))
		((avgDec+=${dec[3]}))
	done
	((avgEnc/=10))
	((avgDec/=10))
	echo $currentLength $avgEnc $avgDec >> $avgFile
done

echo Number of attempts: $attempts >> $targetFile
echo Number of failures: $failedAttempts >> $targetFile

failRate=$(($failedAttempts * 10000 / $attempts))
echo Failure rate: $(($failRate / 100)).$(($failRate % 100))% >> $targetFile
echo FailRate $failedAttempts $attempts >> $avgFile

echo Test complete
echo Test results have been written in $targetFile
echo Reduced average results in $avgFile