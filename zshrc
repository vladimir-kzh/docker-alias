# ------------------------------------
# Docker alias and function
# ------------------------------------

# Get latest container ID
alias dl="docker ps -l -q"

# Get process included stop container
alias dpa="docker ps -a"

# Get images
alias di="docker images"

# Get container IP
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Run deamonized container, e.g., $drund base /bin/echo hello
alias drund="docker run -d -P"

# Run interactive container, e.g., $druni base /bin/bash
alias druni="docker run -i -t -P"

alias dstk="docker stack"

alias ddeploy="docker stack deploy"

alias dslogs="docker service logs"

dps() {
    local name=$1
    if [[ -z "$name" || $name == -* ]]; then
        docker ps $@
    else
        shift
        docker ps --filter="name=$name" $@
    fi
}

# show container ids
dids() {
    dps $@ -q --format="{{.ID}}"
}

# Find container id
did() {
    local name=$1
    if [[ ! -z $name ]]; then shift; fi;
    if [[ ! -z "$name" && "$(dids $@ | grep -i $name | wc -l)" -eq 1 ]]; then
        dids | grep -i $name;
        return 0
    else
        local ids=`dids $name $@`
        local count=`echo $ids | wc -l`
        if [[ -z "$ids" ]]; then
            >&2 echo "Container not found with name: '$name'";
            return 1
        elif [[ "$count" -gt 1 ]]; then
            >&2 echo "Several containers found with name: '$name'";
            >&2 docker ps -a --format="table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" --filter name=$name;
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
        docker exec -it $id $@
    fi
}

dlogs() {
    local id
    if id=$(did $1 -a); then
        shift
        docker logs $@ $id
    fi
}

# Stop container
dstop() {
    # set -x
    if [[ "$1" = "--all" ]]; then
        shift
        docker stop $@ $(docker ps -a -q);
    else
        local id
        if id=$(did $1); then
            shift
            docker stop $@ $id;
        fi
    fi
}

# Remove container
drm() {
    if [[ "$1" = "--all" ]]; then
        shift
        docker rm $@ $(docker ps -a -q);
    else
        local id
        if id=$(did $1 -a); then
            shift
            docker rm $@ $id;
        fi
    fi
}

# Stop and Remove container
drmf() {
    if [[ "$1" = "--all" ]]; then
        shift
        docker stop $(docker ps -a -q);
        docker rm $@ $(docker ps -a -q);
    else
        local id
        if id=$(did $1 -a); then
            shift
            docker stop $id;
            docker rm $@ $id;
        fi
    fi
}

# Remove all images
drmi_all() { docker rmi $(docker images -q); }

# Dockerfile build, e.g., $dbu tcnksm/test 
dbu() { docker build -t=$1 .; }

# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }

# Bash into running container
dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }
