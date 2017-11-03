
path_dir=.
flag_formating=term
flag_verbose=false

flag_input_mode=crlf
flag_output_mode=lf
temp_file_path=./crlf.temp

swapped_files_counter=0
met_files_counter=0

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

function print_help {
  printf "\n"
  printf "Usage:\n"
  printf "    chain_poly  [test_flags] <prog> <dir>\n\n"
  printf "      <prog> is path to the poly calculator executable\n"
  printf "      <dir> is path to the folder containing tests\n"
  printf "            Tests are poly caluclator valid input files\n"
  printf "            containing additionaly special markers:\n"
  printf "               START - appears in the first line of files\n"
  printf "                       indicates that is the first file to be used\n"
  printf "               STOP  - parser stops after current file\n"
  printf "               FILE <filename> - parser load current file and joins\n"
  printf "                       its output with the file <filename> then parses\n"
  printf "                       the concatenated file.\n"
  printf "      Flags are:\n"
  printf "        -s  - silent mode\n"
  printf "            do not display errors, display last valid output of calculator\n"
  printf "        -v  - verbose mode\n"
  printf "            display additional debug info (like file routing etc.)\n"
  printf "        -none-format - use no formatting with produced output\n"
  printf "        -term-format - use default term formatting with produced output\n"
  printf "        -sty-format - use special sty formatting with produced output\n"
  printf "\n"
  exit 0
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

function repair_files {
  for input_file_path in $path_dir/**/*.*
  do
    met_files_counter=$(( met_files_counter + 1 ))
    if [ "$flag_verbose" = "true" ]; then
      printf "${B_DEBUG}[Info] CRLF->LF in file ${input_file_path}${E_DEBUG}\n"
    fi
    if [ -f "$input_file_path" ]; then
      tr -d '\015' < "$input_file_path" > "$temp_file_path"
      cat "$temp_file_path" > "$input_file_path"
      rm "$temp_file_path"
      swapped_files_counter=$(( swapped_files_counter + 1 ))
    else
      printf "${B_ERR}[Error] Could not read file ${input_file_path}${E_ERR}\n"
    fi
  done
}

function print_summary {
  printf "${B_OK}[Done] Changed $swapped_files_counter / $met_files_counter${E_OK}\n"
}

function print_header {
  printf "${B_INFO}[Info] Using $flag_input_mode > $flag_output_mode mode in directory \"$path_dir\"${E_INFO}\n\n"
}

function safe_exit {
  exit $1
}

nonflag_param_count=0
while test $# != 0
do
  case "$1" in
    -help) print_help ;;
    --help) print_help ;;
    -v) flag_verbose=true ;;
    -sty-format) flag_formating=sty ;;
    -term-format) flag_formating=term ;;
    -none-format) flag_formating=none ;;
    -*) {
      printf "${B_ERR}Unknown switch was used: $1${E_ERR}"
      safe_exit 1
    } ;;
    *) {
      if [ "$nonflag_param_count" = "0" ]; then
        path_dir="$1"
      else
        printf "${B_ERR}Wrong number of parameters (too much paths was given?)${E_ERR}\n"
        safe_exit 1
      fi
      nonflag_param_count=$((nonflag_param_count+1))
    } ;;
  esac
  shift
done

set_format
print_header
repair_files
print_summary
