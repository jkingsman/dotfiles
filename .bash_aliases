#!/usr/bin/env bash

DIR="$(dirname "${BASH_SOURCE[0]}")/"

# ------------------------------------------------------------------
# Directory navigation
# ------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias db="cd ~/Dropbox"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias godev="cd ~/Projects; cd '/mnt/d/Projects/Development'"
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
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# ------------------------------------------------------------------
# archive aliases
# ------------------------------------------------------------------
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mktgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias untgz='tar -xvzf'

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
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias gateway='route get default | grep gateway | awk "{print $2}"'
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
        local grepper="cat ~/.bash_history_eternal | GREP_COLOR='1;$colorCount' grep --color=always '$1'";
    else
        local grepper="cat ~/.bash_history | GREP_COLOR='1;$colorCount' grep --color=always '$1'";
    fi

    while shift; do
    colorCount=$((colorCount+1))
        [ -z "$1" ] && continue;
        grepper="$grepper | GREP_COLOR='1;$colorCount' grep --color=always '$1'";
    done;

    eval "$grepper"
}
