#!/usr/bin/env bash
set -e
export SHELL=$(type -p bash)
###############################################
function beginswith { 
case $2 in 
"$1"*) true;; 
*) false
esac
}
function edit_mongerscript {
	if [ $4 ]
	then
		if `grep -q  $'\t'"$2" $4`
		then
			sed -i "s|\t$2.*|\t$2=$3|" $4
		else
			var_value=`echo $3 | sed 's|\/|\\\/|g'`
			sed -i "/^$1:$/{N;s|\[|\[\n\t$2=$var_value|}" $4
		fi
	fi
}
function parse_inputs {
	if ! test -f "$1"
	then
		if ! test -d "$1"
		then
			echo "MONGER RUN ERROR: Could not find input file or directory $1"
			exit 1
		else
			for file in $1/*
			do
				ext=${file##*.}
				if [ "$ext" == "fastq" ]
				then
					outinputs="$outinputs $file"
				fi
			done
		fi
	else
		outinputs=$1
	fi
	echo $outinputs
}

###############################################

while [ "$1" != "" ]
do
	case $1 in
		-i | --inputs)
			while  ! `beginswith "-" $2` && [ "$2" != "" ]
			do
				shift
				inputs="$inputs $1"
			done;;
		--project_name)
			if ! `beginswith "-" $2`
			then
				shift
				project_name=$1
			fi;;
		-N | --name_fields)
			if ! `beginswith "-" $2`
			then
				shift
				name_fields=$1
			fi;;	
		-T | time)
			if ! `beginswith "-" $2`
			then
				shift
				time=$1
			fi;;
		-n | --nodes)
			if ! `beginswith "-" $2`
			then
				shift
				nodes=$1
			fi;;
		-p | --ppn)
			if ! `beginswith "-" $2`
			then
				shift
				ppn=$1
			fi;;
		-M | --mem)
			if ! `beginswith "-" $2`
			then
				shift
				mem=$1
			fi;;
		-E | --email)
			if ! `beginswith "-" $2`
			then
				shift
				email=$1
			fi;;
		-m | --mongerscript)
			if ! `beginswith "-" $2`
			then
				shift
				mongerscript=$1
			fi;;
		-O | --output_dir)
			if ! `beginswith "-" $2`
			then
				shift
				output_dir=$1
			fi;;
		-P | --platform)
			if ! `beginswith "-" $2`
			then
				shift
				platform=$1
			fi;;
		-q | --queue)
			if ! `beginswith "-" $2`
			then
				shift
				queue=$1
			fi;;
		-h | --help)	
			echo -e $usage
			exit 1;;
		*)				
			echo -e $usage
			exit 1;;	
	esac
	shift
done


for input in $inputs
do
	new_inputs=`parse_inputs $input`
	INPUTS="$INPUTS $new_inputs"
done


mkdir -p $output_dir/inputs
mkdir -p $output_dir/mongerscripts
mkdir -p $output_dir/stdout
mkdir -p $output_dir/stderr
mkdir -p $output_dir/qscripts

findpairs.pl -p 2 -o /tmp/input_files.txt -i "$INPUTS"

while read line
do
	name=`echo $line | awk -F' ' '{print $3}' | sed 's|-|_|g' | cut -d'_' -f1-$name_fields`
	line=`echo $line | awk -F' ' -v name="$name" '{$3=name; print}'`
	echo $line | tr ' ' '\t' > $output_dir/inputs/$name.inputs
	echo -e \
"#!/usr/bin/env bash\n\
#PBS -l walltime=$time,nodes=$nodes:ppn=$ppn,mem=$mem\n\
#PBS -M $email\n\
#PBS -N $name\n\
#PBS -o $output_dir/stdout/$name\n\
#PBS -e $output_dir/stderr/$name\n\
#PBS -m abe\n\
#PBS -q $queue\n\n\
module load gcc/4.8.2\n\
. ~/.bashrc\n\
monger run $output_dir/mongerscripts/$name.ms" \
	> $output_dir/qscripts/$name.q
	cp $mongerscript $output_dir/mongerscripts/$name.ms
	read1=`awk '{print $1}' $output_dir/inputs/$name.inputs`
	readname=`head -1 $read1`
	rgid=$name
	rglb=`echo $readname | awk -F':' '{print $2}'`
	rgpu=`echo $readname | awk -F':' '{print $1}'`
	rgpl=$platform
	rgsm=${name%_*}
	rgsm=${rgsm%_*}
	edit_mongerscript \
		PROJECT_INFO \
		PROJECT_NAME \
		$project_name \
		$output_dir/mongerscripts/$name.ms
	edit_mongerscript \
		PROJECT_INFO \
		SUBTHREADS \
		$ppn \
		$output_dir/mongerscripts/$name.ms
	edit_mongerscript \
		PROJECT_INFO \
		READGROUP_INFO \
		"\"RGID=$rgid RGLB=$rglb RGPL=$rgpl RGPU=$rgpu RGSM=$rgsm\"" \
		$output_dir/mongerscripts/$name.ms
	edit_mongerscript \
		INPUT_INFO \
		INPUTS_LIST \
		$output_dir/inputs/$name.inputs \
		$output_dir/mongerscripts/$name.ms
done < /tmp/input_files.txt
	
	
	
	

