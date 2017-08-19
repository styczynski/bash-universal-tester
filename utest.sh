#!/bin/bash

VERSION="1.3.0"
#
# General purpose awesome testing-script
# Used to test program with given .in/.err files
# Or selected script
#
# Usage: type test.sh --help to get some info
#
#
# @Piotr Styczyński 2017
#


flag_formating=term
flag_out_path=./out
flag_err_path=./out
flag_force=false
flag_auto_test_creation=false
flag_skip_ok=false
flag_always_continue=true
flag_skip_summary=false
flag_minimal=false
flag_very_minimal=false
flag_extreamely_minimalistic=false
flag_always_need_good_err=false
flag_good_err_path=
input_prog_flag_acc=
flag_default_require_err_emptyness=false
flag_always_ignore_stderr=false
flag_test_out_script=
flag_test_err_script=
flag_out_path=./test_out_temp
flag_err_path=./test_out_temp
flag_err_temp=true
flag_out_temp=true
file_count=0
flag_tools=
flag_testing_programs=
flag_additional_test_name_info=



C_RED=$(printf "\e[1;31m")
C_GREEN=$(printf "\e[1;32m")
C_BLUE=$(printf "\e[1;34m")
C_CYAN=$(printf "\e[1;36m")
C_PURPLE=$(printf "\e[1;35m")
C_YELLOW=$(printf "\e[1;33m")
C_GRAY=$(printf "\e[1;30m")
C_NORMAL=$(printf "\e[0m")
C_BOLD=$(printf "\e[1m")

B_DEBUG=
E_DEBUG=
B_ERR=
E_ERR=
B_INFO=
E_INFO=
B_WARN=
E_WARN=
B_BOLD=
E_BOLD=
B_OK=
E_OK=



function clean_temp_content {
  if [[ ${flag_out_temp} = 'true' ]]; then
    rm -f -r $flag_out_path/*
  fi
  if [[ ${flag_err_temp} = 'true' ]]; then
    rm -f -r $flag_err_path/*
  fi
}



function clean_temp {
  if [[ ${flag_out_temp} = 'true' ]]; then
    rm -f -r $flag_out_path
  fi
  if [[ ${flag_err_temp} = 'true' ]]; then
    rm -f -r $flag_err_path
  fi
}



function print_help {
  printf "General purpose awesome testing-script v. $VERSION\n\n"
  printf "Usage:\n"
  printf "    test  [test_flags] <prog> <dir> [prog_flags]\n"
  printf "      <prog> is path to the executable, you want to test\n"
  printf "      <dir> is the path to folder containing .in/.out files\n"
  printf "      [prog_flags] are optional conmmand line argument passed to program <prog>\n"
  printf "      [test_flags] are optional flags for test script\n"
  printf "      All available [test_flags] are:\n"
  printf "        --ttools <tools> - set additional debug tools\n"
  printf "           Tools is the coma-separated array of tools names. Tools names can be as the following:\n"
  printf "               * size - prints the size of input file in bytes.\n"
  printf "               * time - prints time statistic using Unix time command.\n"
  printf "               * stime - measures time using bash date command (not as precise as time tool).\n"
  printf "               * vmemcheck - uses valgrind memcheck tools to search for application leaks.\n"
  printf "               * vmassif - uses valgrind massif and prints peak memory usage.\n"
  printf "        --tscript <script> - set output testing command as <script>\n"
  printf "           Script path is path to the executed script/program.\n"
  printf "           There exists few built-in testing scripts:\n"
  printf "               Use '--tscript ignore' to always assume output is OK.\n"
  printf "        --tscript-err <script> - set stderr output testing command as <script>\n"
  printf "           Script path is path to the executed script/program.\n"
  printf "           There exists few built-in testing scripts:\n"
  printf "               Use '--tscript-err ignore' to always assume sterr output is OK.\n"
  printf "        --tflags - enable --t* flags interpreting at any place among command line arguments (by default flags after dir are expected to be program flags)\n"
  printf "        --tsty-format - use !error!, !info! etc. output format\n"
  printf "        --tterm-format - use (default) term color formatting\n"
  printf "        --tc, --tnone-format - use clean character output\n"
  printf "        --ts - Skip oks\n"
  printf "        --tierr - Always ignore stderr output.\n"
  printf "        --tgout <dir> - set (good) .out input directory (default is the same as dir/inputs will be still found in dir location/use when .out and .in are in separate locations)\n"
  printf "        --tgerr <dir> same as --tgout but says where to find good .err files (by default nonempty .err file means error)\n"
  printf "        --terr <dir> - set .err output directory (default is /out)\n"
  printf "        --tout <dir> set output .out file directory (default is /out)\n"
  printf "        --tf - proceed even if directories do not exists etc.\n"
  printf "        --tneed-err, --tnerr - Always need .err files (by default missing good .err files are ignored)\n"
  printf "           If --tnerr flag is used and --tgerr not specified the good .err files are beeing searched in <dir> folder.\n"
  printf "        --te, --tdefault-no-err - If the .err file not exists (ignored by default) require stderr to be empty\n"
  printf "        --tt - automatically create missing .out files using program output\n"
  printf "        --tn - skip after-testing summary\n"
  printf "        --ta - abort after +5 errors\n"
  printf "        -help - display this help\n"
  printf "        --tm - use minimalistic mode (less output)\n"
  printf "        --tmm - use very minimalistic mode (even less output)\n"
  printf "        --tmmm - use the most minimialistic mode (only file names are shown)\n"
  printf "      Wherever -help,--help flags are placed the script always displays its help info.\n"
  printf "\n"
  printf "      About minimalistic modes:\n"
  printf "         In --tm mode OKs are not printed / erors are atill full with diff\n"
  printf "         In --tmm mode errors are only generally descripted / OK at output on success\n"
  printf "         In --tmmm only names of error files are printed / Nothing at output on success\n"
  printf "\n"
}


function update_loc {
  filename="$1"
  folder_loc="$filename"
  es_param_dir=$(echo "${param_dir}" | sed 's:/:\\\/:g')
  es_folder_loc=$(echo "${folder_loc}" | sed 's:/:\\\/:g')
  
  #printf "es_param_dir = ${es_param_dir}\n"
  #printf "es_folder_loc = ${es_folder_loc}\n"
  #printf "       flag_good_err_path = ${flag_good_err_path}\n"
  #printf "       flag_good_out_path = ${flag_good_out_path}\n"
  
  #flag_good_err_path=$(echo "${flag_good_err_path}" | sed -e 's/${es_param_dir}/'$es_folder_loc'/g')
  #flag_good_out_path=$(echo "${flag_good_out_path}" | sed -e 's/${es_param_dir}/'$es_folder_loc'/g')
  flag_good_err_path="${flag_good_err_path//$es_param_dir/$es_folder_loc}"
  flag_good_out_path="${flag_good_out_path//$es_param_dir/$es_folder_loc}"
  
  #printf "after: flag_good_err_path = ${flag_good_err_path}\n"
  #printf "after: flag_good_out_path = ${flag_good_out_path}\n"
  #printf "  NOW OK\n\n"
  
  param_dir="$filename"
}


function prepare_input {

  
  regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  if [[ $param_dir =~ $regex ]]
  then 
    # Link is valid URL so try to download file
    printf "${B_INFO}Trying to download data from provided url...${E_INFO}\n"
    filename=$(curl -sI  $param_dir | grep -o -E 'filename=.*$' | sed -e 's/filename=//')
    if [[ "$filename" = "" ]]; then
      filename="downloaded_tests.zip"
    fi
    if [[ -f $filename ]]; then
      printf "${B_INFO}File already present. Skipping.${E_INFO}\n"
      update_loc "$filename"
    else
      printf "${B_INFO}Download into \"${filename}\"${E_INFO}\n"
      curl -f -L -o "$filename" $param_dir
      curl_status=$?
      if [ "$curl_status" -eq 0 ]; then
        update_loc "$filename"
      else
        printf "${B_ERR}Could not download requested file. :(${E_ERR}\n"
        exit 22
      fi
    fi
  fi

  if [[ -f $param_dir ]]; then
    folder_loc=${param_dir%%.*}
	
    if [[ ! -d "$folder_loc" ]]; then
      printf "${B_INFO}Test input is zip file -- needs unzipping...${E_INFO}\n"
      printf "${B_INFO}This may take a while...${E_INFO}\n"
      mkdir "$folder_loc"
      unzip -q "$param_dir" -d "$folder_loc"
    fi
    
    update_loc "$folder_loc"
    
    # USE AUTOFIND
    best_test_dir=$(autofind_tests "$folder_loc")
    if [[ ${best_test_dir} != '' ]]; then
      printf "${B_DEBUG}Autodected \'$best_test_dir\' as best test directory. Using it.${E_DEBUG}\n"
      update_loc "$best_test_dir"  
    else
      update_loc "$folder_loc"
    fi
    
  fi
}

function autofind_tests {
  # USE AUTOFIND
  best_test_dir=$(find "$1" -maxdepth 3 -type f -name "**.in" -printf '%h\n' | sort | uniq -c | sort -k 1 -r | awk  '{print $2}' | head -n 1)
  printf "$best_test_dir"
}

function verify_args {
  printf "${B_BOLD}--- utest.sh VERSION ${VERSION}v ---${E_BOLD}\n\n"

  if [[ ${flag_force} = 'false' ]]; then

    prog_use_autodetect=false
    prog_autodetect_rel_path=.

    if [[ $param_prog = '' ]]; then
      prog_use_autodetect=true
    fi

    if [[ -d $param_prog ]]; then
      prog_use_autodetect=true
      prog_autodetect_rel_path="$param_prog"
    fi

    if [[ $prog_use_autodetect = 'true' ]]; then

      possible_executables=$(find "$prog_autodetect_rel_path" -perm /u=x,g=x,o=x -type f -printf "%d %p\n" | sort -n| head -n 3 | awk '{print $2}')
      #possible_executables=$(while read -r line; do
      #  stat -c '%Y %n' "$line"
      #done <<< "$possible_executables" | sort -n | cut -d ' ' -f2)

      if [[ $param_prog = '' ]]; then
        printf "${B_ERR}Tested program name was not given. (parameter <prog> is missing)${E_ERR}\n"
        printf "${B_DEBUG}Possible executables to test:\n\n$possible_executables"
        printf "\n\n${B_ERR}Usage: test <prog> <input_dir> [flags]${E_ERR}\n"
        printf "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
        clean_temp
        exit 1
      else
        param_prog=$(echo "$possible_executables" | head -n 1)
        printf "${B_DEBUG}Autodected \'$param_prog\' as best test program. Using it.${E_DEBUG}\n"
      fi
    fi
    if [[ $param_dir = '' ]]; then
      # USE AUTOFIND
      best_test_dir=$(autofind_tests ".")
      if [[ ${best_test_dir} = '' ]]; then
        printf "${B_ERR}Input directory was not given. (parameter <input_dir> is missing)${E_ERR}\n"
        printf "${B_ERR}Usage: test <prog> <input_dir> [flags]${E_ERR}\n"
        printf "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
        clean_temp
        exit 1
      else
        #printf "${B_WARN}Input directory was not given. (parameter <input_dir> is missing)${E_WARN}\n"
        printf "${B_DEBUG}Autodected \'$best_test_dir\' as best test directory. Using it.${E_DEBUG}\n"
        param_dir="$best_test_dir"
        if [[ "$flag_good_out_path" = "" ]]; then
          flag_good_out_path="$param_dir"
        fi
      fi
      #printf "${B_ERR}Input directory was not given. (parameter <input_dir> is missing)${E_ERR}\n"
      #printf "${B_ERR}Usage: test <prog> <input_dir> [flags]${E_ERR}\n"
      #printf "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
      #clean_temp
      #exit 1
    fi
    if [[ -d $param_dir ]]; then
      echo -en ""
    else
      printf "${B_ERR}Input directory \"$param_dir\" does not exists.${E_ERR}\n"
      printf "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
      clean_temp
      exit 1
    fi
  fi
  if [[ ${flag_always_need_good_err} = 'true' ]]; then
    if [[ ${flag_good_err_path} = '' ]]; then
      flag_good_err_path=$param_dir
    fi
  fi
}



function set_format {
  if [[ ${flag_formating} = 'sty' ]]; then
    B_DEBUG="!debug!"
    E_DEBUG="!normal!"
    B_ERR="!error!"
    E_ERR="!normal!"
    B_INFO="!info!"
    E_INFO="!normal!"
    B_WARN="!warn!"
    E_WARN="!normal!"
    B_BOLD="!bold!"
    E_BOLD="!normal!"
    B_OK="!ok!"
    E_OK="!normal!"
  fi
  if [[ ${flag_formating} = 'term' ]]; then
    B_DEBUG=$C_GRAY
    E_DEBUG=$C_NORMAL
    B_ERR=$C_RED
    E_ERR=$C_NORMAL
    B_INFO=$C_BLUE
    E_INFO=$C_NORMAL
    B_WARN=$C_YELLOW
    E_WARN=$C_NORMAL
    B_BOLD=$C_BOLD
    E_BOLD=$C_NORMAL
    B_OK=$C_GREEN
    E_OK=$C_NORMAL
  fi
}



function clean_out_err_paths {
  mkdir -p $flag_out_path
  mkdir -p $flag_err_path
  rm -f -r $flag_out_path/*
  rm -f -r $flag_err_path/*
}


function collect_testing_programs {
  testing_programs_list_str="$param_prog"
  IFS=','
  flag_testing_programs_len=0
  for testing_prog in $testing_programs_list_str
  do
    param_prog="$testing_prog"
    find_testing_program
    flag_testing_programs[${flag_testing_programs_len}]=$param_prog
    flag_testing_programs_len=$((flag_testing_programs_len+1))
  done
  unset IFS
  param_prog="$testing_programs_list_str"
}


function find_testing_program {
  command -v "$param_prog" >/dev/null 2>&1
  if [ "$?" != "0" ]; then
    command -v "./$param_prog" >/dev/null 2>&1
    if [ "$?" != "0" ]; then
      command -v "./$param_prog.exe" >/dev/null 2>&1
      if [ "$?" != "0" ]; then
        command -v "./$param_prog.app" >/dev/null 2>&1
        if [ "$?" != "0" ]; then
          command -v "./$param_prog.sh" >/dev/null 2>&1
          if [ "$?" != "0" ]; then
            #printf "${B_ERR}Invalid program name: ${param_prog}. Program not found.${E_ERR}\n";
            #printf "${B_ERR}Please verify if the executable name is correct.${E_ERR}"
            #clean_temp
            #exit 1
            nothingthere=""
          else
            param_prog=./$param_prog.sh
          fi
        else
          param_prog=./$param_prog.app
        fi
      else
        param_prog=./$param_prog.exe
      fi
    else
      param_prog=./$param_prog
    fi
  fi
}



function count_input_files {
  file_count=0
  for input_file_path in $param_dir/*.in
  do
    file_count=$((file_count+1))
  done
}



function print_summary {
  printf "\n"
  if [[ $flag_minimal = 'false' ]]; then
    if [[ "$not_exists_index" != "0" ]]; then
      printf "  ${B_WARN} $not_exists_index output files do not exits ${E_WARN}\n"
      printf "  ${B_WARN} To create them use --tt flag. ${E_WARN}\n"
    fi
    if [[ "$not_exists_but_created_index" != "0" ]]; then
      printf "  ${B_OK} Created $not_exists_but_created_index new non-existing outputs (with --tt flag) ${E_OK}\n"
    fi
    if [[ $flag_skip_summary = 'false' ]]; then
      if [[ "$ok_index" = "$file_count" ]]; then
        printf "\n${B_OK}Done testing. All $file_count tests passes. ${E_OK}\n"
      else
        printf "\n${B_BOLD}Done testing.${E_BOLD}\n |  ${B_BOLD}TOTAL: $file_count${E_BOLD}\n |  DONE : $((file_index-1))\n |  ${B_WARN}WARN : $warn_index${E_WARN}\n |  ${B_ERR}ERR  : $err_index${E_ERR}\n |  ${B_OK}OK   : $ok_index ${E_OK}\n"
      fi
    fi
  else
    if [[ $flag_extreamely_minimalistic = 'false' ]]; then
      if [[ "$ok_index" = "$file_count" ]]; then
        printf "${B_OK}OK${E_OK}\n"
      fi
    fi
  fi
}



function print_start {
  if [[ $flag_minimal = 'false' ]]; then
    printf "\n"
  fi
  if [[ $flag_minimal = 'false' ]]; then
    printf "${B_BOLD}Performing tests...${E_BOLD}\n"
    printf "${B_DEBUG}Call $param_prog $input_prog_flag_acc ${E_DEBUG}\n\n"
  fi
}



function test_err {
  if [[ "$flag_always_ignore_stderr" = "false" ]]; then
    if [[ $flag_test_err_script != '' ]]; then
      check_testing_script_err
    else
      if [[ "$flag_good_err_path" != "" ]]; then
        if [ "$good_err_path" ]; then
          diff=$(diff --text --minimal --suppress-blank-empty --strip-trailing-cr --ignore-case --ignore-tab-expansion --ignore-trailing-space --ignore-space-change --ignore-all-space --ignore-blank-lines $err_path $good_err_path)
		  
          if [[ $diff != '' ]]; then
            was_error=true
            print_error_by_default=false
            err_index=$((err_index+1))
            err_message=$diff
            err_message=$(echo -en "$err_message" | sed "s/^/ $B_ERR\|$E_ERR  /g")
            if [[ $flag_extreamely_minimalistic = 'false' ]]; then
              printf  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $err_path $flag_additional_test_name_info" "${B_ERR}[ERR] Non matching err-output${E_ERR}"
            else
              printf  "${B_ERR}$err_path $flag_additional_test_name_info${E_ERR}\n"
            fi
            if [[ $flag_very_minimal = 'false' ]]; then
              # We dont want this
              if [[ 'true' = 'false' ]]; then
                printf  "\n  ${B_ERR}_${E_ERR}  \n$err_message\n ${B_ERR}|_${E_ERR}  \n"
              else
                printf  "$err_message\n"
              fi
            fi
          fi

        else
          if [[ ${flag_always_need_good_err} = 'true' ]]; then
            warn_index=$((warn_index+1))
            if [[ ${flag_auto_test_creation} = 'true' ]]; then
              not_exists_but_created_index=$((not_exists_but_created_index+1))
              r=$($param_prog $input_prog_flag_acc < $input_file_path 2> $good_err_path 1> /dev/null)
            else
              not_exists_index=$((not_exists_index+1))
              if [[ "$not_exists_index" -lt "10" ]]; then
                if [[ ${flag_extreamely_minimalistic} = 'true' ]]; then
                  printf  "${B_WARN}$good_err_path $flag_additional_test_name_info${E_WARN}\n"
                else
                  printf  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $input_file $flag_additional_test_name_info" "${B_WARN}[?] $good_err_path not exists${E_WARN}"
                fi
              fi
            fi
          else
            if [[ "$flag_default_require_err_emptyness" = "true" ]]; then
			  if [ -s "$err_path" ]; then
                was_error=true
              fi
            else
              # ERR NOT EXISTS
              # DO NOTHING BY DEFAULT
              echo -en ""
            fi
          fi
        fi
      else
        if [ -s "$err_path" ]; then
          was_error=true
        fi
      fi
    fi
  fi
}












message_accumulator=""
message_last_file_head=""
message_tooling_data_accumulator=""

function push_test_message_with_head {
  message_accumulator_head=""
  message_accumulator_file_head=""
  
  if [[ "$message_accumulator" = "" ]]; then
    message_accumulator_head="${B_DEBUG}[$file_index/$file_count]${E_DEBUG} $input_file    "
    if [ $flag_testing_programs_len -gt 1 ]; then
      message_accumulator="${message_accumulator}\n${message_accumulator_head}\n"
      message_accumulator_head=""
    fi
  fi
  
  message_accumulator_file_head="$flag_additional_test_name_info"
  if [[ "$message_accumulator_file_head" = "$message_last_file_head" ]]; then
    message_accumulator_file_head=""
  else
    message_last_file_head="$message_accumulator_file_head"
  fi
  
  tooling_data="${message_tooling_data_accumulator}"
  if [[ "$1" = "" ]]; then
    message_accumulator_line=$(printf "%s%s%s\n" "${message_accumulator_head}${message_accumulator_file_head}" "$2" "")
  else
    message_accumulator_line=$(printf "%-30s%-30s%s\n" "${message_accumulator_head}${message_accumulator_file_head}" "$1" "${tooling_data}")
  fi
 
  #printf "{PUSH TO ACCUMULATOR ${message_accumulator_line}}"
  message_accumulator="${message_accumulator}\n${message_accumulator_line}"
}

function push_test_message_error {
  push_test_message_with_head "${B_ERR}$1${E_ERR}"
}

function push_test_message_error_details {
  lineprefix=$(printf "%-20s" " ")
  err_message=$(echo -en "$1" | sed "s/^/${lineprefix}${B_ERR}\|${E_ERR}  /g")
  push_test_message_with_head "" "${B_ERR}${err_message}${E_ERR}"
}

function push_test_message_good {
  push_test_message_with_head "${B_OK}[OK]${E_OK}" ""
}

function push_test_message_tooling_info {
  message_tooling_data_accumulator="${message_tooling_data_accumulator} ${B_INFO}[$1]${E_INFO}"
}

function push_test_message_next_program {
  message_tooling_data_accumulator=""
}

function flush_test_messages {
  echo -en "${message_accumulator}"
  message_accumulator=""
  message_last_file_head=""
  message_tooling_data_accumulator=""
}












function flush_err_messages {
  if [[ "$print_error_by_default" = "true" ]]; then
    err_index=$((err_index+1))
    err_message=$(cat "$err_path")
	if [[ $flag_extreamely_minimalistic = 'true' ]]; then
	  push_test_message_error "$input_file"
    else
      if [[ $flag_very_minimal = 'true' ]]; then
      push_test_message_error "Error at stderr"
      else
        push_test_message_error "Error at stderr"
        push_test_message_error_details "$err_message\n"
      fi
    fi
  fi
  clean_temp_content
}

function abort_if_too_many_errors {
  if [[ "$err_index" -gt 5 ]]; then
    if [[ $flag_always_continue = 'false' ]]; then
      printf "\n${B_WARN}[!] Abort testing +5 errors.${E_WARN}\nDo not use --ta flag to always continue."
      clean_temp
      exit 1
    fi
  fi
}

function check_out_script {
  ok=true
  if [[ $diff != '' ]]; then
    if [[ $diff != 'ok' ]]; then
      ok=false
    fi
  fi
  if [[ $ok != 'true' ]]; then
    err_index=$((err_index+1))
    err_message=$diff
    if [[ $flag_extreamely_minimalistic = 'false' ]]; then
      push_test_message_error "Invalid tester answer"
    else
      push_test_message_error "$input_file"
    fi
    if [[ $flag_very_minimal = 'false' ]]; then
      # We dont want this
      if [[ 'true' = 'false' ]]; then
        push_test_message_error "  \n$err_message\n ${B_ERR}|_${E_ERR}  \n"
      else
        push_test_message_error_details "$err_message\n"
      fi
    fi
  else
    ok_index=$((ok_index+1))
    if [[ $flag_skip_ok = 'false' ]]; then
      push_test_message_good
    fi
    rm -f $err_path
  fi
}

function check_out_script_err {
  ok=true
  if [[ $diff != '' ]]; then
    if [[ $diff != 'ok' ]]; then
      ok=false
    fi
  fi
  if [[ $ok != 'true' ]]; then
    was_error=true
    print_error_by_default=false
    err_index=$((err_index+1))
    err_message=$diff
    if [[ $flag_extreamely_minimalistic = 'false' ]]; then
      push_test_message_error "Invalid tester answer for stderr"
    else
      push_test_message_erro "$err_path"
    fi
    if [[ $flag_very_minimal = 'false' ]]; then
      # We dont want this
      if [[ 'true' = 'false' ]]; then
        push_test_message_error_details "  \n$err_message\n ${B_ERR}|_${E_ERR}  \n"
      else
        push_test_message_error_details "$err_message\n"
      fi
    fi
  fi
}

function check_out_diff {
  if [[ $diff != '' ]]; then
    err_index=$((err_index+1))
    err_message=$diff

    if [[ $flag_extreamely_minimalistic = 'false' ]]; then
      push_test_message_error "Non matching output"
    else
      push_test_message_error "$input_file\n"
    fi

    if [[ $flag_very_minimal = 'false' ]]; then
      # We dont want this
      if [[ 'true' = 'false' ]]; then
        push_test_message_error_details "  \n$err_message\n ${B_ERR}|_${E_ERR}  \n"
      else
        push_test_message_error_details "$err_message\n"
      fi
    fi

  else
    ok_index=$((ok_index+1))
    if [[ $flag_skip_ok = 'false' ]]; then
      push_test_message_good
    fi
    rm -f $err_path

  fi
}

function check_testing_script {
  test_not_exists=true
  override_test_command=
  override_test_result=

  if [[ $flag_test_out_script = "ignore" ]]; then
    test_not_exists=false
    override_test_result="ok"
  fi

  if [[ -f "$flag_test_out_script" ]]; then
    test_not_exists=false
  fi
  if [[ $test_not_exists = 'true' ]]; then
      printf  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $input_file $flag_additional_test_name_info" "${B_ERR}[ERR] Testing script does not exists or is invalid command (--tscript). Abort.${E_ERR}"
      printf  "%-30s  %s\n" " " "${B_ERR}Used command: $flag_test_out_script${E_ERR}"

      clean_temp
      exit 1
  else
    if [[ $override_test_result != '' ]]; then
      diff=$override_test_result
    else
      if [[ $override_test_command != '' ]]; then
        diff=$($override_test_command $out_path $good_out_path)
      else
        diff=$($flag_test_out_script $out_path $good_out_path)
      fi
    fi
    check_out_script
  fi
}

function check_testing_script_err {
  test_not_exists=true
  override_test_command=
  override_test_result=

  if [[ $flag_test_err_script = "ignore" ]]; then
    test_not_exists=false
    override_test_result="ok"
  fi

  if [[ -f "$flag_test_err_script" ]]; then
    test_not_exists=false
  fi
  if [[ $test_not_exists = 'true' ]]; then
      printf  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $err_path $flag_additional_test_name_info" "${B_ERR}[ERR] Testing script does not exists or is invalid command (--tscript-err). Abort.${E_ERR}"
      printf  "%-30s  %s\n" " " "${B_ERR}Used command: $flag_test_err_script${E_ERR}"

      clean_temp
      exit 1
  else
    if [[ $override_test_result != '' ]]; then
      diff=$override_test_result
    else
      if [[ $override_test_command != '' ]]; then
        diff=$($override_test_command $err_path $good_err_path)
      else
        diff=$($flag_test_err_script $err_path $good_err_path)
      fi
    fi
    check_out_script_err
  fi
}

function test_out {
  if [[ $flag_test_out_script != '' ]]; then
    check_testing_script
  else
    if [ -e "$good_out_path" ]; then
      diff=$(diff --text --minimal --suppress-blank-empty --strip-trailing-cr --ignore-case --ignore-tab-expansion --ignore-trailing-space --ignore-space-change --ignore-all-space --ignore-blank-lines $out_path $good_out_path)
      check_out_diff
    else
      warn_index=$((warn_index+1))
      if [[ ${flag_auto_test_creation} = 'true' ]]; then
        not_exists_but_created_index=$((not_exists_but_created_index+1))
        r=$($param_prog $input_prog_flag_acc < $input_file_path 1> $good_out_path 2> /dev/null)
      else
        not_exists_index=$((not_exists_index+1))
        if [[ "$not_exists_index" -lt "10" ]]; then
          if [[ ${flag_extreamely_minimalistic} = 'true' ]]; then
            printf  "${B_WARN}$input_file${E_WARN}\n"
          else
            printf  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $input_file $flag_additional_test_name_info" "${B_WARN}[?] $good_out_path not exists${E_WARN}"
          fi
        fi
      fi
    fi
  fi
}

function print_tooling_additional_test_info {
  if [[ $tooling_additional_test_info != '' ]]; then
    tooling_message=$(echo -en "$tooling_additional_test_info" | sed "s/^/   /g")
    printf "${B_DEBUG}${tooling_message}${E_DEBUG}\n"
  fi
}


function run_program {

  tooling_additional_test_info=""

  if [[ $flag_tools_use_stime = 'true' ]]; then
    tool_time_data_stime_start=`date +%s%3N`
  fi

  r=$($param_prog $input_prog_flag_acc < $input_file_path 1> $out_path 2> $err_path)

  if [[ $flag_tools_use_stime = 'true' ]]; then
    tool_time_data_stime_end=`date +%s%3N`
    push_test_message_tooling_info "$((tool_time_data_stime_end-tool_time_data_stime_start))ms"
    #tooling_additional_test_info="${tooling_additional_test_info}Execution time (script dependent): $((tool_time_data_stime_end-tool_time_data_stime_start)) ms\n"
  fi

  if [[ $flag_tools_use_time = 'true' ]]; then
    #r=$($param_prog $input_prog_flag_acc < $input_file_path 1> $out_path 2> $err_path)
    timeOut=$({ time $param_prog $input_prog_flag_acc < $input_file_path 1> /dev/null 2> /dev/null ; } 2>&1 )
    timeOut="$(echo -e "${timeOut}" | sed '/./,$!d')"
    #tooling_additional_test_info="${tooling_additional_test_info}${timeOut}\n"
    timeReal=$(echo "${timeOut}" | grep real | sed -e 's/real//')
    timeReal="$(echo -e "${timeReal}" | tr -d '[:space:]')"
    push_test_message_tooling_info "${timeReal}"
  fi

  if [[ $flag_tools_use_vmassif = 'true' ]]; then
    { valgrind --tool=massif --pages-as-heap=yes --massif-out-file=massif.out $param_prog $input_prog_flag_acc < $input_file_path 1> /dev/null 2> /dev/null ; } > /dev/null 2>&1
    memUsage=$(grep mem_heap_B massif.out | sed -e 's/mem_heap_B=\(.*\)/\1/' | sort -g | tail -n 1)
    memUsage=$(echo "scale=5; $memUsage/1000000" | bc)
    #tooling_additional_test_info="${tooling_additional_test_info}Peak memory usage: ${memUsage}MB\n"
    push_test_message_tooling_info "${memUsage}MB"
    rm ./massif.out
  fi

  if [[ $flag_tools_use_vmemcheck = 'true' ]]; then
    { valgrind --tool=memcheck $param_prog $input_prog_flag_acc < $input_file_path > /dev/null ; } 2> ./memcheck.out
    leaksReport=$(sed 's/==.*== //' ./memcheck.out | sed -n -e '/LEAK SUMMARY:/,$p' | sed 's/LEAK SUMMARY://' | head -5)
    if [[ $leaksReport != '' ]]; then
      #tooling_additional_test_info="${tooling_additional_test_info}Leaks detected / Report:\n${leaksReport}\n"
      push_test_message_tooling_info "Leaks!"
    else
      #tooling_additional_test_info="${tooling_additional_test_info}No leaks possible.\n"
      push_test_message_tooling_info "No leaks"
    fi
    rm ./memcheck.out
  fi
  
  if [[ $flag_tools_use_size = 'true' ]]; then
    inputFileSize=$(stat -c%s "${input_file_path}")
    push_test_message_tooling_info "<${inputFileSize} bytes"
  fi


}

#param_prog=$1
#shift
#param_dir=$1
#shift
#flag_good_out_path=$param_dir


param_counter=0
tflags_loading_enabled=true
tflags_always_load_all=false
while test $# != 0
do
    if [[ ${tflags_loading_enabled} = 'true' ]]; then
      case "$1" in
      --ttools) {
        shift
        flag_tools="$1"
        IFS=','
        #flag_tools=($flag_tools)
        for tool in $flag_tools
        do
          tool=flag_tools_use_${tool}
          eval $tool=true
        done
        unset IFS
      } ;;
      --tscript) shift; flag_test_out_script="$1" ;;
      --tscript-err) shift; flag_test_err_script="$1" ;;
      --tierr) flag_always_ignore_stderr=true ;;
      --tdefault-no-err) flag_default_require_err_emptyness=true ;;
      --te) flag_default_require_err_emptyness=true ;;
      --tflags) tflags_always_load_all=true ;;
      --tneed-err) flag_always_need_good_err=true ;;
      --tnerr) flag_always_need_good_err=true ;;
      --tgout) shift; flag_good_out_path="$1" ;;
      --tgerr) shift; flag_good_err_path="$1" ;;
      --tsty-format) flag_formating=sty ;;
      --tterm-format) flag_formating=term ;;
      --tnone-format) flag_formating=none ;;
      --tc) flag_formating=none ;;
      --tless-info) flag_skip_ok=true ;;
      --tout) shift; flag_out_path="$1"; flag_out_temp=false ;;
      --terr) shift; flag_err_path="$1"; flag_err_temp=false ;;
      --tf) flag_force=true ;;
      --tt) flag_auto_test_creation=true ;;
      --ts) flag_skip_ok=true ;;
      --tn) flag_skip_summary=true ;;
      --ta) flag_always_continue=false ;;
      --tm) flag_skip_ok=true; flag_minimal=true ;;
      --tmm) flag_skip_ok=true; flag_minimal=true; flag_very_minimal=true ;;
      --tmmm) flag_skip_ok=true; flag_minimal=true; flag_very_minimal=true; flag_extreamely_minimalistic=true ;;
      -help) print_help; exit 0;;
      --help) print_help; exit 0;;
      #--t*) printf "ERROR: Unknown test flag: $1 (all flags prefixed with --t* are recognized as test flags)\n"; exit 1 ;;
      *) {
        if [[ $1 == -* ]]; then
          input_prog_flag_acc="$input_prog_flag_acc $1"
        else
          if [[ "$param_counter" == 0 ]]; then
            param_counter=1
            param_prog="$1"
          else
            if [[ "$param_counter" == 1 ]]; then
              param_counter=2
              param_dir="$1"
              if [[ "$flag_good_out_path" = "" ]]; then
                flag_good_out_path="$1"
              fi
              if [[ ${tflags_always_load_all} = 'false' ]]; then
                tflags_loading_enabled=false
              fi
            else
              input_prog_flag_acc="$input_prog_flag_acc $1"
            fi
          fi
        fi
      } ;;
      esac
    else
      case "$1" in
        -help) print_help; exit 0;;
        --help) print_help; exit 0;;
        *) input_prog_flag_acc="$input_prog_flag_acc $1" ;;
      esac
    fi
    shift
done


set_format
prepare_input
verify_args
clean_out_err_paths
collect_testing_programs
#find_testing_program
count_input_files
print_start


file_index=1
err_index=0
ok_index=0
warn_index=0
not_exists_index=0
not_exists_but_created_index=0
tooling_additional_test_info=
for input_file_path in `ls -v $param_dir/*.in`
do
  prog_iter=0
  while [ $prog_iter -lt $flag_testing_programs_len ];
  do
    prog=${flag_testing_programs[${prog_iter}]}
    #echo "|===> Prog ${prog}"
    if [ $flag_testing_programs_len -gt 1 ]; then
      flag_additional_test_name_info="${B_INFO} ${prog} ${E_INFO}"
    else
      flag_additional_test_name_info=""
    fi
    param_prog="$prog"
    if [[ -e $input_file_path ]]; then
      #TEST_RESULTS
      input_file=$(basename $input_file_path)
      good_out_path=$flag_good_out_path/${input_file/.in/.out}
      good_err_path=$flag_good_err_path/${input_file/.in/.err}
      out_path=$flag_out_path/${input_file/.in/.out}
      err_path=$flag_err_path/${input_file/.in/.err}

      run_program

      was_error=false
      print_error_by_default=true
      test_err
      if [[ "$was_error" = "true" ]]; then
        flush_err_messages
        print_tooling_additional_test_info
      else
        abort_if_too_many_errors
        test_out
        print_tooling_additional_test_info
      fi
    fi
    clean_temp_content
    prog_iter=$((prog_iter+1))
    push_test_message_next_program
  done
  
  file_index=$((file_index+1))
  flush_test_messages
done


print_summary
clean_temp
