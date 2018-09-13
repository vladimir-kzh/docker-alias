# ------------------------------------
# Docker alias and function
# ------------------------------------

dckr () {
    if groups | grep docker 2>&1 1>/dev/null; then
        # >&2 echo "INFO: docker $@"
        docker $@
    else
        # >&2 echo "INFO: sudo docker $@"
        sudo docker $@
    fi
}

# Get latest container ID
alias dl="dckr ps -l -q"

# Get process included stop container
alias dpa="dckr ps -a"

# Get images
alias di="dckr images"

# Get container IP
alias dip="dckr inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Run deamonized container, e.g., $drund base /bin/echo hello
alias drund="dckr run -d -P"

# Run interactive container, e.g., $druni base /bin/bash
alias druni="dckr run -i -t -P"

alias dstk="dckr stack"

alias ddeploy="dckr stack deploy"

alias dslogs="dckr service logs"

dps() {
    local name=$1
    if [[ -z "$name" || $name == -* ]]; then
        dckr ps $@
    else
        shift
        dckr ps --filter="name=$name" $@
    fi
}

# show container ids
dids() {
    local ids
    ids=$(dps $@ -q --format="{{.ID}}")
    if [[ -z $ids ]]; then
        >&2 echo "Container not found";
        return 1
    else
        echo $ids
    fi
}

# Find container id
did() {
    local name
    if [[ $1 != -* ]]; then
        name=$1
    fi
    if [[ ! -z $name ]]; then shift; fi;
    if [[ ! -z "$name" && "$(dids $@ | grep -i $name | wc -l)" -eq 1 ]]; then
        dids | grep -i $name;
        return 0
    else
        local ids=`dids $name $@`
        local count=`echo $ids | wc -l`
        if [[ -z "$ids" ]]; then
            return 1
        elif [[ "$count" -gt 1 ]]; then
            >&2 echo "Several containers found with name: '$name'";
            >&2 dckr ps -a --format="table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" --filter name=$name;
            return 1
        else
            echo $ids
            return 0
        fi
    fi
}

# Execute interactive container, e.g., $dex base /bin/bash
dexec() {
    local id
    if id=$(did $1); then
        shift
        dckr exec -it $id $@
    fi
}

dlogs() {
    local id
    if id=$(did $1 -a); then
        shift
        dckr logs $@ $id
    fi
}

# Stop container
dstop() {
    # set -x
    if [[ "$1" = "-a" ]]; then
        shift
        dckr stop $@ $(dckr ps -a -q);
    elif [[ "$2" = "-a" ]]; then
        local ids
        if ids=$(dids $1 $2); then
            shift 2;
            dckr stop $@ $(echo $ids);
        fi
    else
        local id
        if id=$(did $1); then
            shift
            dckr stop $@ $id;
        fi
    fi
}

# Start container
dstart() {
    local id
    if id=$(did $1 -a); then
        shift
        dckr start $@ $id;
    fi
}

# Restart container
drestart() {
    local id
    if id=$(did $1); then
        shift
        dckr restart $@ $id;
    fi
}

# Remove container
drm() {
    if [[ "$1" = "-a" ]]; then
        shift
        dckr rm $@ $(dckr ps -a -q);
    elif [[ "$2" = "-a" ]]; then
        local ids
        if ids=$(dids $1 $2); then
            shift 2;
            dckr rm $@ $(echo $ids);
        fi
    else
        local id
        if id=$(did $1 -a); then
            shift
            dckr rm $@ $id;
        fi
    fi
}

# Stop and Remove container
drmf() {
    if [[ "$1" = "-a" ]]; then
        shift
        dckr stop $(dckr ps -a -q);
        dckr rm $@ $(dckr ps -a -q);
    elif [[ "$2" = "-a" ]]; then
        local ids
        if ids=$(dids $1 $2); then
            shift 2;
            dckr stop $(echo $ids);
            dckr rm $@ $(echo $ids);
        fi
    else
        local id
        if id=$(did $1 -a); then
            shift
            dckr stop $id;
            dckr rm $@ $id;
        fi
    fi
}

# Remove all images
drmi_all() { dckr rmi $(dckr images -q); }

# Dockerfile build, e.g., $dbu tcnksm/test 
dbu() { dckr build -t=$1 .; }

# Show all alias related docker
dalias() { alias | grep 'dckr' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }

# Bash into running container
dbash() { dexec $1 bash; }

# sh into running container
dsh() { dexec $1 sh -l; }
