#!/usr/bin/env bash

VERSION="1.9.4"
IFS=$'\n'

log_container="    [[ UTEST version ${VERSION} ]]    \n\n"
flag_log=false
flag_never_rm=false

function log {
  if [[ "$flag_log" = "true" ]]; then
    time=$(date "+%H:%M:%S")
    message="[${time}] ${1}"
    log_container="${log_container}\n${message}"
  fi
}

function flushlog {
  if [[ "$flag_log" = "true" ]]; then
    log "Flush log to the file."
    echo -e "$log_container" > utest.log
  fi
}


# Dependencies

#
#
# YAML parsing in bash
# Based on https://gist.github.com/pkuczynski/8665367
# And on https://gist.github.com/epiloque/8cf512c6d64641bde388
#
#

#
# Usage: parse_yaml
#   <file>
#   [optional prefix]
#   [optional string "true" -> then it sets all values to ""]
#   [optional string "true" -> use IFS=|next|]
#
parse_yaml() {
    log "Load YAML file \"${1}\""
    #unset IFS
    IFS=$'\n'
    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    if [[ "$3" = "true" ]]; then
      awk -F"$fs" '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
          if (length($3) > 0) {
              vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
              printf("%s%s%s=\"%s\"\n", "'"$prefix"'",vn, $2, "");
          }
      }' | sed 's/_=/+=/g'
    else
      awk -F"$fs" '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
          if (length($3) > 0) {
              vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
              printf("%s%s%s=(\"%s%s\")\n", "'"$prefix"'",vn, $2, $3, "");
          }
      }' | sed 's/_=/+=/g'
    fi
    #IFS=$'\n'
}

# Helper function to generate short universal name
# for tested program

function shortname {
  short_name=$(basename "$1" | tr . _)
  printf "$short_name"
} 


#
#
# Code based on spinner.sh by Tasos Latsas
#
#

# Author: Tasos Latsas

# spinner.sh
#
# Display an awesome 'spinner' while running your long shell commands
#
# Do *NOT* call _spinner function directly.
# Use {start,stop}_spinner wrapper functions

# usage:
#   1. source this script in your's
#   2. start the spinner:
#       start_spinner [display-message-here]
#   3. run your command
#   4. stop the spinner:
#       stop_spinner [your command's exit status]
#
# Also see: test.sh


function _spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success=""
    local on_fail=""
    local white="\e[1;37m"
    local green="\e[1;32m"
    local red="\e[1;31m"
    local nc="\e[0m"

    case $1 in
        start)
      if [[ -z ${3} ]]; then
        let column=1
        # start spinner
        i=1
        sp='\|/-'
        delay=${SPINNER_DELAY:-0.15}
        printf "\n "
        while :
        do
          printf "\b${sp:i++%${#sp}:1}"
          sleep $delay
        done
      else
        sleep 0
      fi
            ;;
        stop)
            if [[ -z ${3} ]]; then
                sleep 0
              else
                kill -9 $3 > /dev/null 2>&1
                while kill -0 $3 2>/dev/null; do sleep 0.005; done
                sleep 0.005
                printf "\b\b\b   \b\b\b  "
              fi
              ;;
        *)
            echo "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

# Disable spinner
spinner_is_running=false
flag_use_spinner=true

function start_spinner {
  if [[ "${flag_use_spinner}|${flag_no_builtin_outputs}" = "true|false" ]]; then
    if [[ "$spinner_is_running" = "false" ]]; then
      spinner_is_running=true
      # $1 : msg to display
      _spinner "start" "${1}" &
      # set global spinner pid
      _sp_pid=$!
      disown
    fi
  fi
}

function stop_spinner {
  if [[ "$spinner_is_running" = "true" ]]; then
    spinner_is_running=false
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
  fi
}

function sbusy {
  start_spinner "$1"
}

function sready {
  stop_spinner 0
}

sbusy ""

#
#
# UTEST.SH
#
#


#
# General purpose awesome testing-script
# Used to test program with given .in/.err files
# Or selected script
#
# Usage: type test.sh --help to get some info
#
#
# @Piotr Styczy?ski 2017
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
flag_out_path=./utest_cache
flag_err_path=./utest_cache
flag_err_temp=false
flag_out_temp=false
file_count=0
flag_tools=
flag_no_builtin_outputs="false"
flag_testing_programs=
flag_additional_test_name_info=
flag_pipe_input=()
flag_pipe_output=()
flag_pipe_err_output=()
param_cwd=""

flag_hook_init=()
flag_hook_deinit=()
flag_hook_test_case_start=()
flag_hook_test_case_finish=()
flag_hook_test_case_fail_err=()
flag_hook_test_case_fail_out=()
flag_hook_test_case_fail=()
flag_hook_test_case_success=()
flag_hook_init_command=()
flag_hook_deinit_command=()

# Should be changed
flag_no_pipes="false"
flag_full_in_path_in_desc="false"

flag_override_good_out_file=
flag_override_good_err_file=


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


bdebug="\${B_DEBUG}"
edebug="\${E_DEBUG}"
berr="\${B_ERR}"
eerr="\${E_ERR}"
binfo="\${B_INFO}"
einfo="\${E_INFO}"
bwarn="\${B_WARN}"
ewarn="\${E_WARN}"
bbold="\${B_BOLD}"
ebold="\${E_BOLD}"
bok="\${B_OK}"
eok="\${E_OK}"

TEXT_OK="OK"

# TODO REMOVE
#sleep 1
#sready
#exit 22

function stdout {
  if [[ "$flag_no_builtin_outputs" = "false" ]]; then
    echo -e $@
  fi
}

function stdoutplain {
  if [[ "$flag_no_builtin_outputs" = "false" ]]; then
    echo -en "$@"
  fi
}

function clean_temp_content {
  log "Clean temp content..."
  if [[ "$flag_never_rm" = "false" ]]; then
    if [[ ${flag_out_temp} = 'true' ]]; then
      log "Clean temp out:\n  rm -f -r $flag_out_path/*"
      if [[ ! "$flag_out_path" = "" ]]; then
        rm -f -r $flag_out_path/*.piped
        rm -f -r $flag_out_path/*.out
        rm -f -r $flag_out_path/*.err
      else
        log "ERROR Try to remove empty flag out path recursively! :(("
      fi
    fi
    if [[ ${flag_err_temp} = 'true' ]]; then
      log "Clean temp err:\n  rm -f -r $flag_err_path/*"
      if [[ ! "$flag_err_path" = "" ]]; then
        rm -f -r $flag_err_path/*.piped
        rm -f -r $flag_err_path/*.out
        rm -f -r $flag_err_path/*.err
      else
        log "ERROR Try to remove empty flag err path recursively! :(("
      fi
    fi
  else
    log "Cleanup blocked (never rm flag is set)"
  fi
  log "Cleanup done."
}



function clean_temp {
  log "Clean temp files..."
  if [[ "$flag_never_rm" = "false" ]]; then
    if [[ ${flag_out_temp} = 'true' ]]; then
      log "Clean temp out:\n  rm -f -r $flag_out_path"
      if [[ ! "$flag_out_path" = "" ]]; then
        if [[ ! "$flag_out_path" = "/" ]]; then
          rm -f -r $flag_out_path
        fi
      fi
    fi
    if [[ ${flag_err_temp} = 'true' ]]; then
      log "Clean temp err:\n  rm -f -r $flag_err_path"
      if [[ ! "$flag_err_path" = "" ]]; then
        if [[ ! "$flag_out_path" = "/" ]]; then
          rm -f -r $flag_err_path
        fi
      fi
    fi
  else
    log "Cleanup blocked (never rm flag is set)"
  fi
  log "Cleanup done."
}

function close {
  run_hook "deinit"
  sready $1
  log "Close (status=${1})"
  flushlog
  exit $1
}



function print_help {
  sready
  log "Display help."
  echo -e "--- utest.sh VERSION ${VERSION}v ---\n\n"
  printf "General purpose awesome testing-script v. $VERSION\n\n"
  printf "Usage:\n"
  printf "    test  [test_flags] <prog> <dir> [prog_flags]\n"
  printf "      <prog> is path to the executable, you want to test\n"
  printf "      <dir> is the path to folder containing .in/.out files\n"
  printf "      [prog_flags] are optional conmmand line argument passed to program <prog>\n"
  printf "      [test_flags] are optional flags for test script\n"
  printf "      All available [test_flags] are:\n"
  printf "        --tdebug - Turns debug mode ON.\n"
  printf "            In debug mode no files are ever deleted!\n"
  printf "            Also logging with --tlog is enabled.\n"
  printf "        --tlog - Enable logging to the utest.log file.\n"
  printf "        --tsilent - Outputs nothing except for the hooks messages.\n"
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
  printf "        --tpipe-in <prog> - Run program input through additional middleware program.\n"
  printf "            You can add more than one piping program.\n"
  printf "            They are executed in order from left to the right.\n"
  printf "            Each program has ability to use \$input and \$output variables.\n"
  printf "            And should read input from \$input file and save it to \$output file.\n"
  printf "            For example --tpipe-in 'cp \$input \$output' to do nothing important.\n"
  printf "        --tpipe-out <prog> - Run program output through additional middleware program.\n"
  printf "            See --tpipe-in.\n"
  printf "        --tpipe-out-err <prog> - Run program std err output through additional middleware program.\n"
  printf "            See --tpipe-in.\n"
  printf "        --tflags - enable --t* flags interpreting at any place among command line arguments (by default flags after dir are expected to be program flags)\n"
  printf "        --tsty-format - use !error!, !info! etc. output format\n"
  printf "        --tterm-format - use (default) term color formatting\n"
  printf "        --tno-spinner - display no spinner\n"
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
  
  log "Update locations.\n  Good error path points to \"${flag_good_err_path}\"\n  Good output path points to \"${flag_good_out_path}\"\n  Param directory points to \"${param_dir}\""
  
}


function prepare_input {

  log "Prepare input files..."

  regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  if [[ ! "${param_prog}" = "" ]]; then
    if [[ "${param_dir}" = "" ]]; then
        if [[ $param_prog =~ $regex ]]
        then
            param_dir="$param_prog"
            param_prog=""
            log "URL detected.\n  Set param directory to point to \"${param_dir}\"."
        fi
    fi
  fi
  
  if [[ $param_dir =~ $regex ]]
  then
    log "Try to download file from \"${param_dir}\"..."
    # Link is valid URL so try to download file
    sready
    stdout "${B_INFO}Trying to download data from provided url...${E_INFO}\n"
    filename=$(curl -sI  $param_dir | grep -o -E 'filename=.*$' | sed -e 's/filename=//')
    if [[ "$filename" = "" ]]; then
      log "Cannot obtain file name. Use default generated."
      filename="downloaded_tests.zip"
    fi
    if [[ -f $filename ]]; then
      sready
      log "Downloaded file is present. Skip download."
      stdout "${B_INFO}File already present. Skipping.${E_INFO}\n"
      update_loc "$filename"
    else
      sready
      stdout "${B_INFO}Download into \"${filename}\"${E_INFO}\n"
      log "Download URL into path \"${filename}\"."
      curl -f -L -o "$filename" $param_dir
      curl_status=$?
      if [ "$curl_status" -eq 0 ]; then
        update_loc "$filename"
      else
        sready
        log "Failed to download the requested file.\n  Curl exit status is ${curl_status}"
        stdout "${B_ERR}Could not download requested file. :(${E_ERR}\n"
        close 22
      fi
    fi
  fi

  if [[ -f $param_dir ]]; then
    log "Detected param directory is a file."
    folder_loc=${param_dir%%.*}
  
    if [[ ! -d "$folder_loc" ]]; then
      sready
      log "Try to unzip file \"${folder_loc}\"."
      stdout "${B_INFO}Test input is zip file -- needs unzipping...${E_INFO}\n"
      stdout "${B_INFO}This may take a while...${E_INFO}\n"
      mkdir "$folder_loc"
      unzip -q "$param_dir" -d "$folder_loc"
      unpackage_status=$?
      if [[ ! "$unpackage_status" = "0" ]]; then
        log "Try to unrar file \"${folder_loc}\"."
        unrar "$param_dir" "$folder_loc" 
        unpackage_status=$?
      fi
      if [[ ! "$unpackage_status" = "0" ]]; then
        log "Try to unpack file (using unp) \"${folder_loc}\"."
        unp "$param_dir" "$folder_loc" 
        unpackage_status=$?
      fi
    fi
    
    update_loc "$folder_loc"
    
    # USE AUTOFIND
    best_test_dir=$(autofind_tests "$folder_loc")
    if [[ ${best_test_dir} != '' ]]; then
      log "Autodected ${best_test_dir} as best testing directory.\n  Using it. :)"
      sready
      stdout "${B_DEBUG}Autodected \'$best_test_dir\' as best test directory. Using it.${E_DEBUG}\n"
      update_loc "$best_test_dir"  
    else
      update_loc "$folder_loc"
    fi
    
  fi
  
  # Look for utest.yaml inside test directory
  log "Look for utest.yaml inside test directory..."
  if [[ -f "${param_dir}/utest.yaml" ]]; then
    if [[ -f "./utest.yaml" ]]; then
       log "Found utest.yaml but it's already present in cwd so skipping!"
       stdout "${B_DEBUG}Found utest.yaml inside tests folder. But yaml file is already present.${E_DEBUG}\n"
    else
       log "Found utest.yaml so copy it :)"
       stdout "${B_DEBUG}Found utest.yaml inside tests folder. Copy it.${E_DEBUG}\n"
       cp -n "${param_dir}/utest.yaml" "./utest.yaml"
       load_global_configuration_file
    fi
  else
    log "Did not found utest.yaml in the test folder (\"${param_dir}/utest.yaml\")"
  fi
}

function autofind_tests {
  # USE AUTOFIND
  log "Try to use autofind functionality..."
  best_test_dir=$(find "$1" -maxdepth 3 -type f -name "**.in" -printf '%h\n' | sort | uniq -c | sort -k 1 -r | awk  '{print $2}' | head -n 1 | tr -d "[:cntrl:]")
  log "Autofind selected:\n  ${best_test_dir}"
  printf "$best_test_dir"
}

function verify_args {
 
  log "Veryfying provided parameters"
 
  if [[ ${flag_force} = 'false' ]]; then

    prog_use_autodetect=false
    prog_autodetect_rel_path=.

    if [[ $param_prog = '' ]]; then
      log "Param prog is empty trigger AUTODETECTION."
      prog_use_autodetect=true
    fi

    if [[ -d $param_prog ]]; then
      log "Param prog is directory trigger AUTODETECTION with hint \"${param_prog}\"."
      prog_use_autodetect=true
      prog_autodetect_rel_path="$param_prog"
    fi

    if [[ $prog_use_autodetect = 'true' ]]; then

      log "Run executable autodetection..."
    
      possible_executables=$(find "$prog_autodetect_rel_path" -perm /u=x,g=x,o=x -type f -printf "%d %p\n" | sort -n| head -n 3 | awk '{print $2}')
      
      log "Possible executables are:\n  ${possible_executables}"
      
      #possible_executables=$(while read -r line; do
      #  stat -c '%Y %n' "$line"
      #done <<< "$possible_executables" | sort -n | cut -d ' ' -f2)

      if [[ $param_prog = '' ]]; then
        log "Print possible executables to the output."
        sready
        stdout "${B_ERR}Tested program name was not given. (parameter <prog> is missing)${E_ERR}\n"
        stdout "${B_DEBUG}Possible executables to test:\n\n$possible_executables"
        stdout "\n\n${B_ERR}Usage: test <prog> <input_dir> [flags]${E_ERR}\n"
        stdout "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
        clean_temp
        close 1
      else
        log "Automatically proceed to testing autodetected programs..."
        param_prog=$(echo "$possible_executables" | head -n 1)
        log "Automatically using program \"${param_prog}\"..."
        sready
        stdout "${B_DEBUG}Autodected '$param_prog' as best test program. Using it.${E_DEBUG}\n"
      fi
    fi
    if [[ $param_dir = '' ]]; then
      # USE AUTOFIND
      log "Param directory was not given so use AUTODETECTION."
      best_test_dir=$(autofind_tests ".")
      log "Best testing directory was determined to be \"${best_test_dir}\"."
      if [[ ${best_test_dir} = '' ]]; then
        log "AUTODETECTION returned nothing so exit."
        sready
        stdout "${B_ERR}Input directory was not given. (parameter <input_dir> is missing)${E_ERR}\n"
        stdout "${B_ERR}Usage: test <prog> <input_dir> [flags]${E_ERR}\n"
        stdout "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
        clean_temp
        close 1
      else
        log "AUTODETECTION returned some result so proceed."
        sready
        #printf "${B_WARN}Input directory was not given. (parameter <input_dir> is missing)${E_WARN}\n"
        stdout "${B_DEBUG}Autodected \'$best_test_dir\' as best test directory. Using it.${E_DEBUG}\n"
        param_dir="$best_test_dir"
        if [[ "$flag_good_out_path" = "" ]]; then
          flag_good_out_path="$param_dir"
        fi
        
        log "Setup autodetected paths.\n  Now param directory points to \"${param_dir}\".\n  And good output path points to \"${flag_good_out_path}\""
      fi
      #sready
      #printf "${B_ERR}Input directory was not given. (parameter <input_dir> is missing)${E_ERR}\n"
      #printf "${B_ERR}Usage: test <prog> <input_dir> [flags]${E_ERR}\n"
      #printf "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
      #clean_temp
      #close 1
    fi
    if [[ -d $param_dir ]]; then
      echo -en ""
    else
      log "Param directory is not a directory! :("
      sready
      
      log "Interpret directory as regex"
      regex_file_list=$(find -regextype posix-extended -regex "${param_dir}" -print0)  
      if [[ "$regex_file_list" != "" ]]; then
        echo -en ""
        log "Regex returned results :)"
      else
        log "Regex failed to return anything"
        log "Interpret directory as globbing pattern"
        regex_file_list=$(ls -v $param_dir 2> /dev/null)  
        if [[ "$regex_file_list" != "" ]]; then
          echo -en ""
          log "Globbing returned results :)"
        else
          log "Globbing failed."
          log "No more directory interpretations. FAIL"
          stdout "${B_ERR}Input directory \"$param_dir\" does not exists.${E_ERR}\n"
          stdout "${B_DEBUG}Use -f option to forcefully proceed.${E_DEBUG}\n"
          clean_temp
          close 1
        fi
      fi
      
    fi
  fi
  if [[ ${flag_always_need_good_err} = 'true' ]]; then
    log "Need good error is set to true so inherit good err path from param directory."
    if [[ ${flag_good_err_path} = '' ]]; then
      flag_good_err_path=$param_dir
    fi
  fi
}



function set_format {
  log "Set output format to { ${flag_formating} }."
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
  log "Clean output error paths."
  log "   mkdir $flag_out_path"
  log "   mkdir $flag_err_path"
  log "   rm -f -r $flag_out_path/*"
  log "   rm -f -r $flag_err_path/*"
  mkdir -p $flag_out_path
  mkdir -p $flag_err_path
  if [[ "${flag_never_rm}}" = "false" ]]; then
    if [[ "${flag_out_temp}}" = "true" ]]; then
        rm -f -r $flag_out_path/*
    fi
    if [[ "${flag_err_temp}" = "true" ]]; then
        rm -f -r $flag_err_path/*
    fi
  else
    log "Removal blocked (flag never rm is set up)."
  fi
}


function collect_testing_programs {
  log "Collecting testing programs..."
  testing_programs_list_str="$param_prog"
  IFS=','
  flag_testing_programs_len=0
  for testing_prog in $testing_programs_list_str
  do
    param_prog="$testing_prog"
    find_testing_program
    log "Collected \"${testing_prog}\" as \"${param_prog}\""
    flag_testing_programs[${flag_testing_programs_len}]=$param_prog
    flag_testing_programs_len=$((flag_testing_programs_len+1))
  done
  unset IFS
  IFS=$'\n'
  log "Collected all programs."
  param_prog="$testing_programs_list_str"
}


function find_testing_program {
  log "Find testing program with hint \"${param_prog}\"..."
  command -v "$param_prog" >/dev/null 2>&1
  if [ "$?" != "0" ]; then
    log "Program is not a valid command"
    command -v "./$param_prog" >/dev/null 2>&1
    if [ "$?" != "0" ]; then
      log "Program is not a valid \"./NAME\" style command"
      command -v "./$param_prog.exe" >/dev/null 2>&1
      if [ "$?" != "0" ]; then
        log "Program is not a valid \"./NAME.exe\" style command"
        command -v "./$param_prog.app" >/dev/null 2>&1
        if [ "$?" != "0" ]; then
          log "Program is not a valid \"./NAME.app\" style command"
          command -v "./$param_prog.sh" >/dev/null 2>&1
          if [ "$?" != "0" ]; then
            log "Program is not a valid \"./NAME.sh\" style command"
            log "No more options end testing and override no settings. :("
            #sready
            #printf "${B_ERR}Invalid program name: ${param_prog}. Program not found.${E_ERR}\n";
            #printf "${B_ERR}Please verify if the executable name is correct.${E_ERR}"
            #clean_temp
            #close 1
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
  log "Try to count input files..."
  # Count input files
  unset IFS
  file_count=0
  for input_file_path in $input_file_list
  do
    file_count=$((file_count+1))
  done
  log "Counted ${file_count} files."
  IFS=$'\n'
}


function find_input_files {
  log "Try to find input files for \"${param_dir}\"..."
  regex_file_matching="false"
  #
  # input file list sorted by ascending file size
  #
  #input_file_list=`ls -vhS $param_dir/*.in | tr ' ' '\n'|tac|tr '\n' ' '`
  log "Find ${param_dir}/*.in"
  input_file_list=$(ls -v $param_dir/*.in 2> /dev/null)
  input_file_list_err_code=$?

  if [[ "$input_file_list_err_code" != "0" ]]; then
    #
    # Obtain file list by using globs
    #
    log "Find ${param_dir}"
    input_file_list=$(ls -v $param_dir 2> /dev/null)
    input_file_list_err_code=$?
    regex_file_matching="true"
  fi

  if [[ "$input_file_list_err_code" != "0" ]]; then
    #
    # Obtain file list by using regexes
    #
    log "Find regex ${param_dir}"
    input_file_list=$(find -regextype posix-extended -regex "${param_dir}" -printf "%p  ")
    input_file_list_err_code=$?
    regex_file_matching="true"
  fi
}

function run_testing {
  log "Run testing..."
  sbusy
  file_index=1
  err_index=0
  ok_index=0
  warn_index=0
  not_exists_index=0
  not_exists_but_created_index=0
  tooling_additional_test_info=
  unset IFS
  for input_file_path in $input_file_list
  do
    prog_iter=0
    IFS=$'\n'
    while [ $prog_iter -lt $flag_testing_programs_len ];
    do
      sbusy
      prog=${flag_testing_programs[${prog_iter}]}
      
      log "Tested input ${input_file_path} for program ${prog}"
      
      
      #echo "|===> Prog ${prog}"
      if [ $flag_testing_programs_len -gt 1 ]; then
        flag_additional_test_name_info="${B_INFO} ${prog} ${E_INFO}"
      else
        flag_additional_test_name_info=""
      fi
      
      #printf "Evaluated prog is -> $param_prog_eval\n"
      
      if [[ -e $input_file_path ]]; then
      
        #
        # When we use regexes 
        #
        if [[ "$regex_file_matching" = "true" ]]; then
          if [[ "$flag_good_out_path" = "$param_dir" ]]; then
            flag_good_out_path=$(dirname "$input_file_path")
          fi
          if [[ "$flag_good_err_path" = "$param_dir" ]]; then
            flag_good_err_path=$(dirname "$input_file_path")
          fi
        fi
      
        param_prog="$prog"
      
        #TEST_RESULTS
        input_file=$(basename $input_file_path)
        input_file_name=${input_file/.in/}
        input_file_folder=$(dirname "$input_file_path")
        
        # If input file name does not contain .in extension
        if [[ "${input_file/.in/}" = "$input_file" ]]; then
          input_file_name=${input_file}
        fi
        
        #
        # Parse dynamic paths
        #
        flag_good_out_path_unparsed=$flag_good_out_path
        flag_good_err_path_unparsed=$flag_good_err_path
        
        flag_good_out_path=$(evalspecplain "$flag_good_out_path")
        flag_good_err_path=$(evalspecplain "$flag_good_err_path")
        
        if [[ "$flag_good_out_path" != "$flag_good_out_path_unparsed" ]]; then
          good_out_path="$flag_good_out_path"
        else
          good_out_path=$flag_good_out_path_unparsed
        fi
        
        if [[ "$flag_good_err_path" != "$flag_good_err_path_unparsed" ]]; then
          good_err_path="$flag_good_err_path"
        else
          good_err_path=$flag_good_err_path_unparsed
        fi
        
        if [[ ! -f "$good_out_path" ]]; then
          good_out_path=$flag_good_out_path/${input_file/.in/.out}
        fi
        if [[ ! -f "$good_err_path" ]]; then
          good_err_path=$flag_good_err_path/${input_file/.in/.err}
        fi
        if [[ ! -f "$out_path" ]]; then
          out_path=$flag_out_path/${input_file/.in/.out}
        fi
        if [[ ! -f "$err_path" ]]; then
          err_path=$flag_err_path/${input_file/.in/.err}
        fi
        single_test_configuration_file_path=${input_file_path/.in/.config.yaml}
        
        
        # If input file name does not contain .in extension
        if [[ "${input_file/.in/}" = "$input_file" ]]; then
          if [[ ! -f "$good_out_path" ]]; then
            good_out_path=$flag_good_out_path/${input_file}.out
          fi
          if [[ ! -f "$good_err_path" ]]; then
            good_err_path=$flag_good_err_path/${input_file}.err
          fi
          if [[ ! -f "$out_path" ]]; then
            out_path=$flag_out_path/${input_file}.out
          fi
          if [[ ! -f "$err_path" ]]; then
            err_path=$flag_err_path/${input_file}.err
          fi
          single_test_configuration_file_path=${input_file_path}.config.yaml
        fi
        
        
        param_prog="$prog"
        param_prog_eval=$(evalspecplain "$param_prog")
        param_prog="$param_prog_eval"
        
        # Load test configuration
        return_buffer=""
        load_single_test_configuration_file
        
        run_hook "init_command"
        
        run_hook "test_case_start"
        run_program
        
        run_hook "deinit_command"

        was_error=false
        want_to_skip_other_programs=false
        print_error_by_default=true
        test_err
        if [[ "$was_error" = "true" ]]; then
          run_hook "test_case_fail"
          run_hook "test_case_fail_err"
          flush_err_messages
          print_tooling_additional_test_info
        else
          abort_if_too_many_errors
          test_out
          print_tooling_additional_test_info
        fi
        
        run_hook "test_case_finish"
        
        # Unload configuration
        unload_single_test_configuration_file
        
        #
        # Move back to unparsed paths
        #
        flag_good_out_path=$flag_good_out_path_unparsed
        flag_good_err_path=$flag_good_err_path_unparsed
        
        if [[ "$want_to_skip_other_programs" = "true" ]]; then
          break
        fi
      fi
      clean_temp_content
      prog_iter=$((prog_iter+1))
      push_test_message_next_program
      sready
    done
    
    sbusy
    file_index=$((file_index+1))
    flush_test_messages
    unset IFS
  done
  IFS=$'\n'
}

function print_summary {
  log "Print testing summary."
  sready
  stdout "\n"
  if [[ $flag_minimal = 'false' ]]; then
    if [[ "$not_exists_index" != "0" ]]; then
      stdout "  ${B_WARN} $not_exists_index output files do not exits ${E_WARN}\n"
      stdout "  ${B_WARN} To create them use --tt flag. ${E_WARN}\n"
    fi
    if [[ "$not_exists_but_created_index" != "0" ]]; then
      stdout "  ${B_OK} Created $not_exists_but_created_index new non-existing outputs (with --tt flag) ${E_OK}\n"
    fi
    if [[ $flag_skip_summary = 'false' ]]; then
      if [[ "$ok_index" = "$file_count" ]]; then
        stdout "\n${B_OK}Done testing. All $file_count tests passes. ${E_OK}\n"
      else
        stdout "\n${B_BOLD}Done testing.${E_BOLD}\n |  ${B_BOLD}TOTAL: $file_count${E_BOLD}\n |  DONE : $((file_index-1))\n |  ${B_WARN}WARN : $warn_index${E_WARN}\n |  ${B_ERR}ERR  : $err_index${E_ERR}\n |  ${B_OK}${TEXT_OK}   : $ok_index ${E_OK}\n"
      fi
    fi
  else
    if [[ $flag_extreamely_minimalistic = 'false' ]]; then
      if [[ "$ok_index" = "$file_count" ]]; then
        stdout "${B_OK}${TEXT_OK}${E_OK}\n"
      fi
    fi
  fi
}



function print_start {
  log "Print initial message"
  if [[ $flag_minimal = 'false' ]]; then
    sready
  stdout "\n"
  fi
  if [[ $flag_minimal = 'false' ]]; then
    sready
    stdout "${B_BOLD}Performing tests...${E_BOLD}\n"
    prog_short_name=$(shortname "$param_prog")
    stdout "${B_DEBUG}Call $param_prog $input_prog_flag_acc (short name: ${prog_short_name}) ${E_DEBUG}\n\n"
    log "Call $param_prog $input_prog_flag_acc (short name: ${prog_short_name})\n\n"
  fi
}



function test_err {
  log "Test error output"
  if [[ "$flag_always_ignore_stderr" = "false" ]]; then
    if [[ $flag_test_err_script != '' ]]; then
      check_testing_script_err
    else
      if [[ "$flag_good_err_path" != "" ]]; then
        if [ "$good_err_path" ]; then
          log "Diff \"${err_path}\" \"${good_err_path}\""
          diff=$(diff --text --minimal --suppress-blank-empty --strip-trailing-cr --ignore-case --ignore-tab-expansion --ignore-trailing-space --ignore-space-change --ignore-all-space --ignore-blank-lines $err_path $good_err_path)
      
          if [[ $diff != '' ]]; then
            log "Diff is not empty :("
            was_error=true
            print_error_by_default=false
            err_index=$((err_index+1))
            err_message=$diff
            err_message=$(echo -en "$err_message" | sed "s/^/ $B_ERR\|$E_ERR  /g")
            if [[ $flag_extreamely_minimalistic = 'false' ]]; then
              sready
              stdout  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $err_path $flag_additional_test_name_info" "${B_ERR}[ERR] Non matching err-output${E_ERR}"
            else
              sready
              stdout  "${B_ERR}$err_path $flag_additional_test_name_info${E_ERR}\n"
            fi
            if [[ $flag_very_minimal = 'false' ]]; then
              # We dont want this
              if [[ 'true' = 'false' ]]; then
                sready
                stdout  "\n  ${B_ERR}_${E_ERR}  \n$err_message\n ${B_ERR}|_${E_ERR}  \n"
              else
                sready
                stdout  "$err_message\n"
              fi
            fi
          fi

        else
          log "Good error path not found"
          if [[ ${flag_always_need_good_err} = 'true' ]]; then
            warn_index=$((warn_index+1))
            if [[ ${flag_auto_test_creation} = 'true' ]]; then
              not_exists_but_created_index=$((not_exists_but_created_index+1))
              log "Create good err output file \"$good_err_path\""
              r=$($param_prog $input_prog_flag_acc < $input_file_path 2> $good_err_path 1> /dev/null)
            else
              log "Just display warnning and proceed"
              not_exists_index=$((not_exists_index+1))
              if [[ "$not_exists_index" -lt "10" ]]; then
                if [[ ${flag_extreamely_minimalistic} = 'true' ]]; then
                  sready
                  stdout  "${B_WARN}$good_err_path $flag_additional_test_name_info${E_WARN}\n"
                else
                  sready
                  want_to_skip_other_programs=true
                  stdout  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $input_file" "${B_WARN}[?] $good_err_path not exists${E_WARN}"
                fi
              fi
            fi
          else
            if [[ "$flag_default_require_err_emptyness" = "true" ]]; then
              log "Err output emptyness testing..."
              if [ -s "$err_path" ]; then
                log "Err output is not empty :("
                was_error=true
              fi
            else
              log "Good err file does not exist and required emptyness is set to false. So do nothing."
              # ERR NOT EXISTS
              # DO NOTHING BY DEFAULT
              echo -en ""
            fi
          fi
        fi
      else
        log "Good err output path is empty so just test for error emptyness..."
        if [ -s "$err_path" ]; then
          log "Error output is not empty :("
          was_error=true
        fi
      fi
    fi
  fi
}

function safename {
  echo "$1" | tr -cd '[[:alnum:]].@_-'
}

function filein {
    echo "${1}" >> "${flag_out_path}/_cache_buffer_in.temp"
    echo "${1}"
}

function fileout {
    echo "${1}" >> "${flag_out_path}/_cache_buffer_out.temp"
    echo "${1}"
}

function clear_cache_buffer {
    mkdir -p $flag_out_path
    echo "" > "${flag_out_path}/_cache_buffer_in.temp"
    echo "" > "${flag_out_path}/_cache_buffer_out.temp"
}

function evalspec {
  code="${1/\%/\$}"
  clear_cache_buffer
  
  cached_ins=$(cat "${flag_out_path}/_cache_buffer_in.temp")
  cached_outs=$(cat "${flag_out_path}/_cache_buffer_out.temp")
  
  for cached_in in "$cached_ins"
  do
    log "[CACHED] IN {${cached_in}}"
  done
  
  eval $code
}

function evalspecplain {
  incode="${1}"
  code="${1//\%/\$}"
  clear_cache_buffer
  code=$(eval echo "$code")
  latest_out_timestamp=0
  skip=true
  skiplog=""
  
  if [[ "$incode" == *"%(fileout"* || "$incode" == *"%(filein"* ]]; then
      # Out files
      while read file; do
        if [[ ! "$file" = "" ]]; then
            if [[ ! -f "$file" ]]; then
               skiplog="${skiplog}OUT $file do not exist./n"
               skip=false
            else
                out_timestamp=$(stat -c %Y "$file")
                skiplog="${skiplog}OUT TIME $file IS $out_timestamp./n"
                if [[ ( "$out_timestamp" > "$latest_out_timestamp" ) ]]; then
                    latest_out_timestamp="$out_timestamp"
                fi
            fi
        fi
      done <"${flag_out_path}/_cache_buffer_out.temp"
      
      
      # In files
      while read file; do
        if [[ ! "$file" = "" ]]; then
            if [[ -f "$file" ]]; then
                in_timestamp=$(stat -c %Y "$file")
                skiplog="${skiplog}IN TIME $file IS $in_timestamp AND LATEST OUT IS $latest_out_timestamp./n"
                if [[ ( "$in_timestamp" > "$latest_out_timestamp" ) ]]; then
                    skip=false
                fi
            else
                skiplog="${skiplog}IN $file do not exist./n"
            fi
        fi
      done <"${flag_out_path}/_cache_buffer_in.temp"
      
      if [[ "$skip" = "false" ]]; then
        echo "$code"
      else
        echo "echo \"\""
      fi
  else
    echo "$code"
  fi
}

#
# Usage: load_prop_variable <variable_prefix> <variable_name> <output_variable> <false_to_disable_parsing>
#
function load_prop_variable {
  log "Load traced variable ${1}${2} into ${3}"
  input_var_name="${1}${2}"
  output_var_name="${3}"
  output_var_name=$(safename "${output_var_name}")
  input_var_name=$(safename "${input_var_name}")
  input_var_value_raw="${!input_var_name}"
  input_var_value="$input_var_value_raw"
  if [[ "$4" != "false" ]]; then
    input_var_value=$(evalspecplain "$input_var_value_raw")
  fi
  output_var_value="${!output_var_name}"
  
  if [[ "${input_var_value}" != '' ]]; then
    return_buffer="${output_var_name}=\"${output_var_value}\"\n${return_buffer}"
    #printf "load_prop_variable ${output_var_name} -> ${input_var_value}\n"
    eval $output_var_name="\$input_var_value"
  fi
}

#
# Usage: load_prop_value <value> <output_variable> <false_to_disable_parsing>
#
function load_prop_value {
    log "Load traced value ${1} into ${2}"
    temp_prop_variable_cap="${1}"
    load_prop_variable "" "temp_prop_variable_cap" "${2}" "{3}"
    temp_prop_variable_cap=""
}

#
# Usage: load_prop_variable_arr <variable_prefix> <variable_name> <output_variable>
#
function load_prop_variable_arr {
  log "Load traced array ${1}${2} into ${3}"
  input_var_name="${1}${2}[@]"
  output_var_name="${3}"
  input_var_name=$(safename "${input_var_name}")
  output_var_name=$(safename "${output_var_name}")
  
  #input_var_value=$(eval echo "\"\${${input_var_name}[@]}\"")
  input_var_value=$(safename "${input_var_value}")
  output_var_value=$(safename "${output_var_value}")
  input_var_value=( ${!input_var_name} )
  output_var_value=( ${!output_var_name} )
  
  if [[ "${input_var_value[@]}" != '' ]]; then
      return_buffer="${output_var_name}=( ${!output_var_name} )\n${return_buffer}"
      #printf "load_prop_variable ${output_var_name} -> ${input_var_value}\n"   
      #eval $output_var_name=\$input_var_value
      eval $output_var_name=\( \${!input_var_name} \)
      #printf "cur val => ${!output_var_name}\n"
  fi
}


function load_global_configuration_file {
  log "Load global configuration file \"${global_configuration_file_path}\""
  return_buffer=""
  global_configuration_file_path="./utest.yaml"
  if [ -f "$global_configuration_file_path" ]; then
    log "Configuration file exists so proceed"
    #
    # Load global configuration file
    #
    
    #printf "LOAD GLOBAL CONFIURATION FILE ${global_configuration_file_path}\n"
    configuration_parsed_setup=$(parse_yaml "${global_configuration_file_path}" "global_config_" "false" "true")
    #configuration_parsed_setup="${configuration_parsed_setup}"
    
    #printf "IFS on global load: ${IFS}\n"
    #printf "Global setup file contents:\n$configuration_parsed_setup\n"
    eval "$configuration_parsed_setup"
    
    load_prop_variable "global_config_" "input" "param_dir" "false"
    load_prop_variable "global_config_" "good_output" "flag_good_out_path" "false"
    load_prop_variable "global_config_" "good_err" "flag_good_err_path" "false"
      
    load_prop_variable "global_config_" "need_error_files" "flag_always_need_good_err" "false"
    load_prop_variable "global_config_" "silent" "flag_no_builtin_outputs" "false"
      
    load_prop_variable "global_config_" "testing_script_out" "flag_test_out_script"
    load_prop_variable "global_config_" "testing_script_err" "flag_test_err_script"
    
    load_prop_variable_arr "global_config_" "hooks__init_" "flag_hook_init"
    load_prop_variable_arr "global_config_" "hooks__deinit_" "flag_hook_deinit"
    
    load_prop_variable_arr "global_config_" "hooks__test_case_start_" "flag_hook_test_case_start"
    load_prop_variable_arr "global_config_" "hooks__test_case_finish_" "flag_hook_test_case_finish"
    load_prop_variable_arr "global_config_" "hooks__test_case_fail_err_" "flag_hook_test_case_fail_err"
    load_prop_variable_arr "global_config_" "hooks__test_case_fail_out_" "flag_hook_test_case_fail_out"
    load_prop_variable_arr "global_config_" "hooks__test_case_fail_" "flag_hook_test_case_fail"
    load_prop_variable_arr "global_config_" "hooks__test_case_success_" "flag_hook_test_case_success"
    
    
    
    #printf "HERE flag_good_out_path => ${flag_good_out_path}\n"
    
    if [[ "$global_config_executions_" != "" ]]; then
      prog_arr_parser_acc=""
      for prog in "${global_config_executions_[@]}"
      do
        #printf "prog -> ${prog}\n"
        if [[ "$prog_arr_parser_acc" = "" ]]; then
          prog_arr_parser_acc="\"${prog}\""
        else
          prog_arr_parser_acc="${prog_arr_parser_acc},\"${prog}\""
        fi
      done
      load_prop_variable "" "prog_arr_parser_acc" "param_prog"
    fi
    
  else
    log "Global configuration file not found :("
  fi
  return_buffer=""
}

function load_single_test_configuration_file {
  log "Load single test configuration file \"${single_test_configuration_file_path}\""
  return_buffer=""
  
  short_name=$(shortname "$param_prog")
  if [[ "$param_prog_call_name" != "" ]]; then
    short_name=$(shortname "$param_prog_call_name")
  fi
  #printf "short_name :=> $short_name\n"
  
  config_prefix="test_config_${short_name}__"
  global_config_prefix="global_config_${short_name}__"
  
  #printf "glob config prefix: ${global_config_prefix}test\n"
  
  # Load global config
  load_prop_variable "${global_config_prefix}" "command" "param_prog"
  
  load_prop_variable_arr "${global_config_prefix}" "init_" "flag_hook_init_command"
  load_prop_variable_arr "${global_config_prefix}" "deinit_" "flag_hook_deinit_command"
  
  load_prop_variable "${global_config_prefix}" "cwd" "param_cwd"
  load_prop_variable "${global_config_prefix}" "args" "input_prog_flag_acc"
  load_prop_variable "${global_config_prefix}" "input" "input_file_path"
  
  load_prop_variable_arr "${global_config_prefix}" "pipes_out_" "flag_pipe_output"
  load_prop_variable_arr "${global_config_prefix}" "pipes_out_err_" "flag_pipe_err_output"
  load_prop_variable_arr "${global_config_prefix}" "pipes_in_" "flag_pipe_input"
  
  #load_prop_variable "${global_config_prefix}" "testing_script_out" "flag_test_out_script"
  #load_prop_variable "${global_config_prefix}" "testing_script_err" "flag_test_err_script"
  
  
  #flag_test_out_script
  
  if [ -f "$single_test_configuration_file_path" ]; then
    log "Configuration file exists so proceed"
    #
    # Load configuration file for single test execution
    #
    
    #printf "LOAD CONFIURATION FILE ${single_test_configuration_file_path}\n"
    configuration_parsed_setup=$(parse_yaml "${single_test_configuration_file_path}" "test_config_" "false" | grep "$short_name")
    
    #printf "CONFIG:\n"
    #printf "$configuration_parsed_setup\n"
    
    eval "$configuration_parsed_setup"
    
    load_prop_variable "${config_prefix}" "args" "input_prog_flag_acc"
    
    #printf "input_prog_flag_acc ==> ${input_prog_flag_acc}\n"
    
    # Sotre call name of prog
    load_prop_variable "" "param_prog" "param_prog_call_name" "false"
    load_prop_variable "${config_prefix}" "command" "param_prog"
    load_prop_variable "${config_prefix}" "cwd" "param_cwd"
    
    load_prop_variable "${config_prefix}" "input" "input_file_path"
    
    load_prop_variable "${config_prefix}" "good_output" "flag_good_out_path" "false"
    load_prop_variable "${config_prefix}" "good_err" "flag_good_err_path" "false"
      
    load_prop_variable "${config_prefix}" "need_error_files" "flag_always_need_good_err" "false"
      
    load_prop_variable "${config_prefix}" "testing_script_out" "flag_test_out_script"
    load_prop_variable "${config_prefix}" "testing_script_err" "flag_test_err_script"
    
    #printf "elelele\n"
    #printf "$configuration_parsed_setupsss\n"
    
    #printf "Return buffer:\n${return_buffer}"
  else
    log "Single test configuration file not found :("
  fi
}

function unload_single_test_configuration_file {
  
  log "Unload single test configuration..."
  
  # Backup pre-global settings
  backup_global_config_script=$(printf "$return_buffer")
  eval "$backup_global_config_script"
  
  if [ -f "$single_test_configuration_file_path" ]; then
    #
    # Unload configuration file for single test execution
    #
    configuration_parsed_teardown=$(parse_yaml "${single_test_configuration_file_path}" "test_config_" "true")
    
    backup_config_script=$(printf "$configuration_parsed_teardown")
    
    #printf "backup config:\n"
    #printf "$backup_config_script"
    
    eval "$backup_config_script"
  fi
}

#
# Usage: run_hook <hook_name>
#
function run_hook {
  log "Run hook ${1}"
  sbusy
  hook_name="flag_hook_${1}[@]"
  hook_name=$(safename "${hook_name}")
  hook_value=( ${!hook_name} )
  
  hook_result=""
  silent_mode="false"
  if [[ "${hook_value[@]}" != "" ]]; then
    log "Execute hook listeners... :)"
    for hook_command_raw in "${hook_value[@]}"
    do
      
      hook_command=$(evalspecplain "${hook_command_raw}")
      log "Execute hook command:\n   ${hook_command_raw}\n   Translated: ${hook_command}"
      
      #echo -en "Hook:command |${hook_command}|\n"
      
      # Check for silent mode
      if [[ "${hook_command:0:1}" = "@" ]]; then
        hook_command="${hook_command#?}"
        silent_mode="true"
      fi
      
      #echo -en "HOOK COMMAND IS ${hook_command}"
      
      hook_command_result=$(eval "${hook_command}")
      status=$?
      
      if [[ ! "${status}" = "0" ]]; then
        log "ERROR Hook command returned non-zero status! Report problems! :("
        log "Finished executing hook."
        stdout "${B_ERR}Hook returned non zero exit code:\n|  Hook: ${1}\n|  Program: ${param_prog}\n|  Test case: ${input_file_path}\n|  Command: ${hook_command}${E_ERR}\n"
        close 1
      fi
      
      if [[ "${hook_command_result}" != "" ]]; then
        if [[ "$silent_mode" = "false" ]]; then
          if [[ "$hook_result" != "" ]]; then
            hook_result="${hook_result}\n> "
          else
            hook_result="> "
          fi
        fi
        hook_result="${hook_result}${hook_command_result}\n"
      fi
    done
  else
    log "No hook listeners found! :("
  fi
  if [[ "${hook_result}" != "" ]]; then
    sready
    if [[ "$silent_mode" = "false" ]]; then
      stdout "${B_INFO}[hook:${1}]${E_INFO}\n${hook_result}\n"
    else
      stdout "${hook_result}"
    fi
    sbusy
  fi
  log "Finished executing hook."
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
  push_test_message_with_head "${B_OK}[${TEXT_OK}]${E_OK}" ""
}

function push_test_message_tooling_info {
  message_tooling_data_accumulator="${message_tooling_data_accumulator} ${B_INFO}[$1]${E_INFO}"
}

function push_test_message_next_program {
  message_tooling_data_accumulator=""
}

function flush_test_messages {
  sready
  stdoutplain "${message_accumulator}      "
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
      log "Too many errors. ABORT"
      sready
      stdout "\n${B_WARN}[!] Abort testing +5 errors.${E_WARN}\nDo not use --ta flag to always continue."
      clean_temp
      close 1
    fi
  fi
}

function check_out_script {
  log "Check output testing script results"
  ok=true
  if [[ $diff != '' ]]; then
    if [[ $diff != 'ok' ]]; then
      log "Diff is not empty and not ok :("
      ok=false
    fi
  fi
  if [[ $ok != 'true' ]]; then
    log "Test failure detected. :("
    err_index=$((err_index+1))
    err_message=$diff
    
    run_hook "test_case_fail"
    run_hook "test_case_fail_out"
    
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
    run_hook "test_case_success"
    
    ok_index=$((ok_index+1))
    if [[ $flag_skip_ok = 'false' ]]; then
      push_test_message_good
    fi
    if [[ "$flag_never_rm" = "false" ]]; then
      rm -f $err_path
    else
      log "Err output removal was blocked (flag never rm is set up)."
    fi
  fi
}

function check_out_script_err {
  log "Check error output testing script results"
  ok=true
  if [[ $diff != '' ]]; then
    if [[ $diff != 'ok' ]]; then
      log "Diff is not empty and not ok :("
      ok=false
    fi
  fi
  if [[ $ok != 'true' ]]; then
    log "Test failure detected. :("
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
  log "Check output diff results"
  if [[ $diff != '' ]]; then
    log "Diff is not empty :("
    log "Test failure detected. :("
    err_index=$((err_index+1))
    err_message=$diff

    run_hook "test_case_fail"
    run_hook "test_case_fail_out"
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
    run_hook "test_case_success"
    ok_index=$((ok_index+1))
    if [[ $flag_skip_ok = 'false' ]]; then
      push_test_message_good
    fi
    if [[ "$flag_never_rm" = "false" ]]; then
      rm -f $err_path
    else
      log "Error output removal was blocked (flag never rm is set up)."
    fi

  fi
}

function check_testing_script {
  log "Run testing script for output..."
  test_not_exists=true
  override_test_command=
  override_test_result=

  if [[ $flag_test_out_script = "ignore" ]]; then
    log "IGNORE testing script used."
    test_not_exists=false
    override_test_result="ok"
  fi

  if [[ -f "$flag_test_out_script" ]]; then
    log "Testing script does not exist :("
    test_not_exists=false
  fi
  if [[ $test_not_exists = 'true' ]]; then
      sready
      stdout  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $input_file $flag_additional_test_name_info" "${B_ERR}[ERR] Testing script does not exists or is invalid command (--tscript). Abort.${E_ERR}"
      stdout  "%-30s  %s\n" " " "${B_ERR}Used command: $flag_test_out_script${E_ERR}"

      clean_temp
      close 1
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
  log "Run testing script for error output..."
  test_not_exists=true
  override_test_command=
  override_test_result=

  if [[ $flag_test_err_script = "ignore" ]]; then
    log "IGNORE testing script used."
    test_not_exists=false
    override_test_result="ok"
  fi

  if [[ -f "$flag_test_err_script" ]]; then
    log "Testing script does not exist :("
    test_not_exists=false
  fi
  if [[ $test_not_exists = 'true' ]]; then
      sready
      stdout  "%-35s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG}  $err_path $flag_additional_test_name_info" "${B_ERR}[ERR] Testing script does not exists or is invalid command (--tscript-err). Abort.${E_ERR}"
      stdout  "%-30s  %s\n" " " "${B_ERR}Used command: $flag_test_err_script${E_ERR}"

      clean_temp
      close 1
  else
    if [[ $override_test_result != '' ]]; then
      diff=$override_test_result
    else
      if [[ $override_test_command != '' ]]; then
        log "Execute testing script\n   $override_test_command $err_path $good_err_path"
        diff=$($override_test_command $err_path $good_err_path)
      else
        log "Execute testing script\n   $flag_test_err_script $err_path $good_err_path"
        diff=$($flag_test_err_script $err_path $good_err_path)
      fi
    fi
    check_out_script_err
  fi
}

function test_out {
  log "Test output..."
  if [[ $flag_test_out_script != '' ]]; then
    check_testing_script
  else
    if [ -e "$good_out_path" ]; then
      log "Check diff of $out_path $good_out_path"
      diff=$(diff --text --minimal --suppress-blank-empty --strip-trailing-cr --ignore-case --ignore-tab-expansion --ignore-trailing-space --ignore-space-change --ignore-all-space --ignore-blank-lines $out_path $good_out_path)
      check_out_diff
    else
      warn_index=$((warn_index+1))
      if [[ ${flag_auto_test_creation} = 'true' ]]; then
        not_exists_but_created_index=$((not_exists_but_created_index+1))
        log "Create test output file:\n  $param_prog $input_prog_flag_acc < $input_file_path 1> $good_out_path 2> /dev/null"
        r=$($param_prog $input_prog_flag_acc < $input_file_path 1> $good_out_path 2> /dev/null)
      else
        log "Good output file does not exist :("
        not_exists_index=$((not_exists_index+1))
        if [[ "$not_exists_index" -lt "10" ]]; then
          if [[ ${flag_extreamely_minimalistic} = 'true' ]]; then
            sready
            stdout  "${B_WARN}$input_file${E_WARN}\n"
          else
            sready
            want_to_skip_other_programs=true
            stdout  "\n%-28s  %s\n" "${B_DEBUG}[$file_index/$file_count]${E_DEBUG} $input_file" "${B_WARN}[?] $good_out_path not exists${E_WARN}"
          fi
        fi
      fi
    fi
  fi
}

function print_tooling_additional_test_info {
  if [[ $tooling_additional_test_info != '' ]]; then
    tooling_message=$(echo -en "$tooling_additional_test_info" | sed "s/^/   /g")
    sready
    stdout "${B_DEBUG}${tooling_message}${E_DEBUG}\n"
  fi
}

#
# Usage: run_program_pipe <input_file> <output_file> <pipes>
#
function run_program_pipe {
  log "Run piping for \"${1}\" -> \"${2}\""
  input_orig="${1}"
  input="${2}"
  output="${2}.temp"

  # Copy input to piped input file
  cp -f "$input_orig" "$input"
  
  if [[ "$3" != "" ]]; then
    for pipe in "$3"
    do
      
      log "Run pipe\n   ${pipe}"
      
      #
      # Pipe file from $input -> to $output
      #
      evalspec "$pipe"
      
      # Copy result back from output to input
      # then remove output file
      if [[ -f "$output" ]]; then
        log "Copy file:\n  cp -f \"$output\" \"$input\""
        cp -f "$output" "$input"
      fi
      log "Remove output file:\n  rm -f \"$output\""
      if [[ "$flag_never_rm" = "false" ]]; then
        rm -f "$output"
      else
        log "Output file removal was blocked (flag never rm is set up)."
      fi
      
    done
  fi
  log "Pipes exit."
}

function run_program {

  log "Run program"

  tooling_additional_test_info=""
  r=""
  
  # Perpare input piping
  if [[ "$flag_no_pipes" != "true" ]]; then
    # Pipe input
    run_program_pipe "$input_file_path" "${input_file_path}.piped" "${flag_pipe_input[@]}"
  fi
  
  
  target_input="${input_file_path}"
  target_out="${out_path}"
  target_err="${err_path}"
   
  # There are no pipes used so do not operate on files
  if [[ ! "$flag_no_pipes" = "true" ]]; then
    target_input="${input_file_path}.piped"
    target_out="${out_path}.piped"
    target_err="${err_path}.piped"
  fi
  
  target_command="$param_prog $input_prog_flag_acc < \"${target_input}\" 1> \"${target_out}\" 2> \"${target_err}\""
  target_command_mocked="$param_prog $input_prog_flag_acc < \"${target_input}\" 1> /dev/null 2> /dev/null"
  target_command_mocked_push_err="$param_prog $input_prog_flag_acc < \"${target_input}\" 1> /dev/null"
  
  
  if [[ ! "$param_cwd" = "" ]]; then
    eval_call="( cd $param_cwd ; ${param_prog} ${input_prog_flag_acc} )"
    log "CWD switched!"
    target_command="$eval_call < \"${target_input}\" 1> \"${target_out}\" 2> \"${target_err}\""
  fi
  
  log "Run program... Pipe to:\n  < \"${target_input}\"\n  1> \"${target_out}\"\n  2> \"${target_err}\" "
  log "Full command is:\n  ${target_command}"
  
  if [[ $flag_tools_use_stime = 'true' ]]; then
    tool_time_data_stime_start=`date +%s%3N`
  fi

  r=$(eval $target_command)

  if [[ $flag_tools_use_stime = 'true' ]]; then
    tool_time_data_stime_end=`date +%s%3N`
    push_test_message_tooling_info "$((tool_time_data_stime_end-tool_time_data_stime_start))ms"
    #tooling_additional_test_info="${tooling_additional_test_info}Execution time (script dependent): $((tool_time_data_stime_end-tool_time_data_stime_start)) ms\n"
  fi

  if [[ $flag_tools_use_time = 'true' ]]; then
    #r=$($param_prog $input_prog_flag_acc < $input_file_path 1> $out_path 2> $err_path)
    timeOut=$({ time $target_command_mocked ; } 2>&1 )
    timeOut="$(echo -e "${timeOut}" | sed '/./,$!d')"
    #tooling_additional_test_info="${tooling_additional_test_info}${timeOut}\n"
    timeReal=$(echo "${timeOut}" | grep real | sed -e 's/real//')
    timeReal="$(echo -e "${timeReal}" | tr -d '[:space:]')"
    push_test_message_tooling_info "${timeReal}"
  fi

  if [[ $flag_tools_use_vmassif = 'true' ]]; then
    { valgrind --tool=massif --pages-as-heap=yes --massif-out-file=massif.out $target_command_mocked ; } > /dev/null 2>&1
    memUsage=$(grep mem_heap_B massif.out | sed -e 's/mem_heap_B=\(.*\)/\1/' | sort -g | tail -n 1)
    memUsage=$(echo "scale=5; $memUsage/1000000" | bc)
    #tooling_additional_test_info="${tooling_additional_test_info}Peak memory usage: ${memUsage}MB\n"
    push_test_message_tooling_info "${memUsage}MB"
    if [[ "$flag_never_rm" = "false" ]]; then
      rm ./massif.out
    else
      log "Massif output file removal was blocked (flag never rm is set up)."
    fi
  fi

  if [[ $flag_tools_use_vmemcheck = 'true' ]]; then
    { valgrind --tool=memcheck $target_command_mocked_push_err ; } 2> ./memcheck.out
    leaksReport=$(sed 's/==.*== //' ./memcheck.out | sed -n -e '/LEAK SUMMARY:/,$p' | sed 's/LEAK SUMMARY://' | head -5)
    if [[ $leaksReport != '' ]]; then
      #tooling_additional_test_info="${tooling_additional_test_info}Leaks detected / Report:\n${leaksReport}\n"
      push_test_message_tooling_info "Leaks!"
    else
      #tooling_additional_test_info="${tooling_additional_test_info}No leaks possible.\n"
      push_test_message_tooling_info "No leaks"
    fi
    if [[ "$flag_never_rm" = "false" ]]; then
      rm ./memcheck.out
    else
      log "Memcheck output file removal was blocked (flag never rm is set up)."
    fi
  fi
  
  if [[ $flag_tools_use_size = 'true' ]]; then
    inputFileSize=$(stat -c%s "${target_input}")
    push_test_message_tooling_info "<${inputFileSize} bytes"
  fi
  
  # Do output piping
  if [[ "$flag_no_pipes" != "true" ]]; then
    # Pipe output
    run_program_pipe "${out_path}.piped" "${out_path}" "${flag_pipe_output[@]}"
    
    # Pipe err output
    run_program_pipe "${err_path}.piped" "${err_path}" "${flag_pipe_err_output[@]}"
    
    
    # Remove unwanted piping files
    log "Remove unwanted piping files\n  rm -f \"${input_file_path}.piped\"\n  rm -f \"${out_path}.piped\""
    if [[ "$flag_never_rm" = "false" ]]; then
      rm -f "${input_file_path}.piped"
      rm -f "${out_path}.piped"
    else
      log "Piping files removal was blocked (flag never rm is set up)."
    fi
  fi

  log "Finished running program."
}

function run_utest {
  log "Started utest main body :)"
  sbusy
  set_format
  load_global_configuration_file
  prepare_input
  verify_args
  clean_out_err_paths
  collect_testing_programs
  #find_testing_program
  #count_input_files
  print_start
  find_input_files
  count_input_files
  run_hook "init"
  run_testing
  sbusy
  print_summary
  run_hook "deinit"
  sready
  clean_temp
  log "Quitted utest main body"
}

#
# BODY OF UTEST
# Loads CLI arguments then
# proceeds to run_utest function
#

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
        IFS=$'\n'
      } ;;
      --tdebug) flag_log=true; flag_never_rm=true ;;
      --tlog) flag_log=true ;;
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
      --tno-spinner) flag_use_spinner=false ;;
      --tsilent) flag_no_builtin_outputs="true" ;;
      --tc) flag_formating=none ;;
      --tless-info) flag_skip_ok=true ;;
      --tout) shift; flag_out_path="$1"; flag_out_temp=false ;;
      --terr) shift; flag_err_path="$1"; flag_err_temp=false ;;
      --tf) flag_force=true ;;
      --tt) flag_auto_test_creation=true ;;
      --ts) flag_skip_ok=true ;;
      --tn) flag_skip_summary=true ;;
      --ta) flag_always_continue=false ;;
      --tpipe-out-err) shift; flag_no_pipes="false"; flag_pipe_err_output+=("$1") ;;
      --tpipe-out) shift; flag_no_pipes="false"; flag_pipe_output+=("$1") ;;
      --tpipe-in) shift; flag_no_pipes="false"; flag_pipe_input+=("$1") ;;
      --tm) flag_skip_ok=true; flag_minimal=true ;;
      --tmm) flag_skip_ok=true; flag_minimal=true; flag_very_minimal=true ;;
      --tmmm) flag_skip_ok=true; flag_minimal=true; flag_very_minimal=true; flag_extreamely_minimalistic=true ;;
      -help) print_help; close 0;;
      --help) print_help; close 0;;
      #--t*) printf "ERROR: Unknown test flag: $1 (all flags prefixed with --t* are recognized as test flags)\n"; close 1 ;;
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
        -help) print_help; close 0;;
        --help) print_help; close 0;;
        *) input_prog_flag_acc="$input_prog_flag_acc $1" ;;
      esac
    fi
    shift
done
run_utest
sready

log "Exit utest..."
if [[ "$err_index" != "0" ]]; then
   close 1
fi
close 0

