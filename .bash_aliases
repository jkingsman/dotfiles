#!/usr/bin/env bash

# ------------------------------------------------------------------
# Directory navigation
# ------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
db() { cd /mnt/d/Dropbox 2>/dev/null || cd ~/Dropbox; }
dl() { cd /mnt/d/Downloads 2>/dev/null || cd ~/Downloads; }
dt() { cd /mnt/d/Desktop 2>/dev/null || cd ~/Desktop; }
godev() { cd /mnt/d/Projects/Development 2>/dev/null || cd ~/Projects; }
alias e.="open ."

# ------------------------------------------------------------------
# Git goodies
# ------------------------------------------------------------------
alias gl="git log --oneline --all --graph --decorate  $*"
alias gs="git status"
alias ga="git add --all ."
alias gp="git push"
alias gd="git diff"
alias gsa="git stash"
alias gsp="git stash pop"
alias gsd="git stash drop"
gco(){
    git fetch
    git stash
    git checkout $@
    git unfuck
    git pull
}
gcp(){
    git commit -am "$@"
    git push
}
alias gcpa="git add . && git commit --amend --no-edit && git push --force"
alias master="git stash; git unfuck || echo 'unfuck failed; continuing'; git checkout master && git pull"
alias main="git stash; git unfuck  || echo 'unfuck failed; continuing'; git checkout main && git pull"
alias buildkick="git commit --allow-empty -m 'Kick the build' && git push"
alias gchp="git cherry-pick"
alias gchpc="git add . && git cherry-pick --continue"

# ------------------------------------------------------------------
# chmod
# ------------------------------------------------------------------
alias mx='chmod a+x'
alias chmodx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# ------------------------------------------------------------------
# archive aliases
# ------------------------------------------------------------------
mktar() {
  if [ $# -eq 2 ]; then
    tar -cvf "$1" "$2"
  elif [ $# -eq 1 ]; then
    dir="${1%/}"
    tar -cvf "${dir##*/}.tar" "$dir"
  else
    echo "Usage: mktar [archive.tar] <dir> OR mktar <dir>"
    return 1
  fi
}
mkbz2() {
  if [ $# -eq 2 ]; then
    tar -cvjf "$1" "$2"
  elif [ $# -eq 1 ]; then
    dir="${1%/}"
    tar -cvjf "${dir##*/}.tar.bz2" "$dir"
  else
    echo "Usage: mkbz2 [archive.tar.bz2] <dir> OR mkbz2 <dir>"
    return 1
  fi
}
mktgz() {
  if [ $# -eq 2 ]; then
    tar -cvzf "$1" "$2"
  elif [ $# -eq 1 ]; then
    dir="${1%/}"
    tar -cvzf "${dir##*/}.tar.gz" "$dir"
  else
    echo "Usage: mktgz [archive.tar.gz] <dir> OR mktgz <dir>"
    return 1
  fi
}

alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias untgz='tar -xvzf'

# from https://stackoverflow.com/a/48250807
extract () {
    if [ -f "$1" ] ; then
        case $1 in
            *.tar.bz2)   tar xvjf "$1" ;;
            *.tar.gz)    tar xvzf "$1" ;;
            *.tar.xz)    tar xvJf "$1" ;;
            *.bz2)       bunzip2 "$1" ;;
            *.rar)       unrar x "$1" ;;
            *.gz)        gunzip "$1" ;;
            *.tar)       tar xvf "$1" ;;
            *.tbz2)      tar xvjf "$1" ;;
            *.tgz)       tar xvzf "$1" ;;
            *.zip)       unzip "$1" ;;
            *.jar)       unzip "$1" ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1" ;;
            *)           echo "'$1' cannot be extracted via >extract<" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ------------------------------------------------------------------
# Terraform
# ------------------------------------------------------------------
alias tf="terraform"
alias tfs="terraform state"

# ------------------------------------------------------------------
# Quick servers
# ------------------------------------------------------------------
alias srv="python -m SimpleHTTPServer || python -m http.server 8000 || python3 -m http.server 8000"
alias srv3="python -m SimpleHTTPServer || python -m http.server 8000 || python3 -m http.server 8000"

# ------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------
function ips() {
  if command -v ip > /dev/null 2>&1; then
    # Use `ip` if available (Linux, modern Unix)
    ip -o addr show | awk '
      {
        iface = $2;
        family = ($3 == "inet") ? "IPv4" : ($3 == "inet6" ? "IPv6" : $3);
        ipaddr = $4;
        type = (iface ~ /^(wlan|wl|wifi)/) ? "Wi-Fi" :
               (iface ~ /^(eth|en)/) ? "Ethernet" : "Other";
        print "Interface: " iface ", Type: " type ", " family ": " ipaddr;
      }
    '
    # Get default gateway
    gw=$(ip route | awk '/default/ {print $3}')
    echo "Default Gateway: $gw"

  elif command -v netstat > /dev/null 2>&1 && netstat -rn 2>/dev/null | grep -q '^default'; then
    # Use netstat fallback (macOS, BSD)
    ifconfig | awk '
      /^[a-zA-Z0-9]/ { iface=$1; sub(/:/, "", iface); next }
      /inet / {
        type = (iface ~ /^(en|eth)/) ? "Ethernet" :
               (iface ~ /^(wl|wifi)/) ? "Wi-Fi" : "Other";
        print "Interface: " iface ", Type: " type ", IPv4: " $2
      }
      /inet6 / {
        type = (iface ~ /^(en|eth)/) ? "Ethernet" :
               (iface ~ /^(wl|wifi)/) ? "Wi-Fi" : "Other";
        print "Interface: " iface ", Type: " type ", IPv6: " $2
      }
    '
    gw=$(netstat -rn | awk '/^default/ {print $2; exit}')
    echo "Default Gateway: $gw"

  elif command -v ipconfig > /dev/null 2>&1; then
    # macOS-specific fallback
    for iface in $(networksetup -listallhardwareports | awk '/Device/ {print $2}'); do
      ip=$(ipconfig getifaddr "$iface" 2>/dev/null)
      if [ -n "$ip" ]; then
        porttype=$(networksetup -listallhardwareports | awk -v dev="$iface" '
          $0 ~ "Hardware Port" { port=$3 }
          $0 ~ "Device: "dev { print port }
        ')
        echo "Interface: $iface, Type: ${porttype:-Unknown}, IPv4: $ip"
      fi
    done
    gw=$(netstat -rn | awk '/^default/ {print $2; exit}')
    echo "Default Gateway: $gw"

  else
    echo "No supported network tool (ip, ifconfig, ipconfig) found."
    return 1
  fi

  # Fetch and display external IP
  if command -v curl > /dev/null 2>&1; then
    ext_ip=$(curl -s ipinfo.io/ip)
    echo "External IP: $ext_ip"
  else
    echo "curl not found; cannot fetch external IP."
  fi
}

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
  alias "${method}"="lwp-request -m '${method}'"
done

alias status="curl -s -o /dev/null -w \"%{http_code}\""

# ------------------------------------------------------------------
# Random utilities
# ------------------------------------------------------------------
alias where="find . | grep -i"
alias searchcase="grep -rnw . -e"
alias search="grep -irnw . -e" # case insensitive contents grep

# pretty print command with escaped newlines, indents, etc.
pretty_command() {
    # Check if input is provided
    if [ $# -eq 0 ]; then
        echo "Usage: pretty_command 'your command with args and flags'"
        return 1
    fi

    local cmd="$*"
    local base_cmd=""
    local result=""
    local indent="    "
    local in_base_cmd=true

    # Split the command into words
    read -ra words <<< "$cmd"

    for word in "${words[@]}"; do
        # Check if the word is a flag/switch (starts with - or --)
        if [[ "$word" =~ ^- ]]; then
            # If this is the first flag, end the base command section
            if $in_base_cmd; then
                in_base_cmd=false
                base_cmd="${base_cmd% }"  # Remove trailing space
                printf "%s \\\\\n" "$base_cmd"
            else
                # Add the previous flag line with continuation
                printf "%s%s \\\\\n" "$indent" "$last_flag"
            fi
            last_flag="$word"
        elif ! $in_base_cmd; then
            # This is a value for the previous flag
            last_flag="$last_flag $word"
        else
            # This is part of the base command
            base_cmd="$base_cmd$word "
        fi
    done

    # Add the last flag without continuation
    if ! $in_base_cmd; then
        printf "%s%s\n" "$indent" "$last_flag"
    else
        printf "%s\n" "$base_cmd"
    fi
}

# run a command n times (ntimes 50 curl example.com) or do it asynchronously (ntimes a 50 curl example.com)
function ntimes() {
  local async=0
  if [ "$1" == "a" ]; then
    async=1
    shift
  fi
  local n=$1
  shift
  for ((i=1; i<=n; i++)); do
    echo "Run #$i"
    if [ $async -eq 1 ]; then
      "$@" &
    else
      "$@"
    fi
  done
  if [ $async -eq 1 ]; then
    wait
  fi
}

# youtube downloading
alias yta="yt-dlp -x --audio-format mp3 --audio-quality 0"
alias ytd="yt-dlp -f bestvideo+bestaudio -ciw --add-metadata --embed-subs --all-subs -o '%(title)s.%(ext)s' -v"

# search text in python files
alias pygrep='grep -r * --include=*.py -e '

# macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# Trim new lines and copy to clipboard
alias c="tr -d '\n' | pbcopy"

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec ${SHELL} -l"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

alias _nmap='nmap -A -p- -T4 -Pn'

# launch bash in a docker image
drun (){
    if [ "$#" -gt 1 ]; then
        echo "docker run -itu root $1 ${@:2}"
        docker run -itu root $1 ${@:2}
    else
        docker run -itu root $1 bash
    fi
}

# turn a markdown file into an epub
ebookify(){
        fullfile=$@
        filename=$(basename -- "$fullfile")
        filename="${filename%.*}"
        extension="${filename##*.}"

        pandoc -f gfm -s "$fullfile" --metadata title="$filename" --metadata pagetitle="$filename" -o "$filename.epub" --epub-title-page=false
}

# Create a quick playground to work in
play(){
  rm -rf /tmp/playground
  mkdir /tmp/playground
  cd /tmp/playground
}

# website cloning
alias clone='wget --wait=1 --level=inf --recursive --page-requisites --user-agent=Mozilla --no-parent --convert-links --adjust-extension --no-clobber --restrict-file-names=windows -e robots=off'

# random password
gen_passwd(){
  local len="${1:-32}"
  shuf -er -n$len {A..Z} {a..z} {0..9} | tr -d '\n'
}

# python venvs
alias vmake='python3 -m venv venv'
alias va='source venv/bin/activate'
alias va3='source venv36/bin/activate'

# add me to the passwordless sudoers list
alias sudo_no_passwd="echo \"$USER ALL=(ALL:ALL) NOPASSWD: ALL\" | sudo tee /etc/sudoers.d/$USER"

# ------------------------------------------------------------------
# History search & config
# ------------------------------------------------------------------
alias yesterday="cat ~/.bash_history_eternal | tail -25"
hgrep(){
    [ -z "$1" ] && echo "Syntax: ${FUNCNAME[0]} <PATTERN> [<PATTERN>...]" 1>&2 && return 1;

    local colorCount=31
    # check if we have a ~/.bash_history_eternal file
    if [ -f ~/.bash_history_eternal ]; then
        local grepper="cat ~/.bash_history_eternal | GREP_COLOR='1;$colorCount' grep -a --color=always '$1'";
    else
        local grepper="cat ~/.bash_history | GREP_COLOR='1;$colorCount' grep -a --color=always '$1'";
    fi

    while shift; do
    colorCount=$((colorCount+1))
        [ -z "$1" ] && continue;
        grepper="$grepper | GREP_COLOR='1;$colorCount' grep -a --color=always '$1'";
    done;

    eval "$grepper"
}
