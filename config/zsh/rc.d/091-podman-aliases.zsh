#
# Defines podman aliases.
#
# Author:
#   François Vantomme <akarzim@gmail.com>
#

#
# Aliases
#

# podman
alias pd='podman'
alias pda='podman attach'
alias pdb='podman build'
alias pdd='podman diff'
alias pddf='podman system df'
alias pde='podman exec'
alias pdE='podman exec -it'
alias pdh='podman history'
alias pdi='podman images'
alias pdin='podman inspect'
alias pdim='podman import'
alias pdk='podman kill'
alias pdl='podman logs'
alias pdli='podman login'
alias pdlo='podman logout'
alias pdls='podman ps'
alias pdp='podman pause'
alias pdP='podman unpause'
alias pdpl='podman pull'
alias pdph='podman push'
alias pdps='podman ps'
alias pdpsa='podman ps -a'
alias pdr='podman run'
alias pdR='podman run -it --rm'
alias pdRe='podman run -it --rm --entrypoint /bin/bash'
alias pdRM='podman system prune'
alias pdrm='podman rm'
alias pdrmi='podman rmi'
alias pdrn='podman rename'
alias pds='podman start'
alias pdS='podman restart'
alias pdss='podman stats'
alias pdsv='podman save'
alias pdt='podman tag'
alias pdtop='podman top'
alias pdup='podman update'
alias pdV='podman volume'
alias pdv='podman version'
alias pdw='podman wait'
alias pdx='podman stop'

## Container (C)
alias pdC='podman container'
alias pdCa='podman container attach'
alias pdCcp='podman container cp'
alias pdCd='podman container diff'
alias pdCe='podman container exec'
alias pdCin='podman container inspect'
alias pdCk='podman container kill'
alias pdCl='podman container logs'
alias pdCls='podman container ls'
alias pdCp='podman container pause'
alias pdCpr='podman container prune'
alias pdCrn='podman container rename'
alias pdCS='podman container restart'
alias pdCrm='podman container rm'
alias pdCr='podman container run'
alias pdCR='podman container run -it --rm'
alias pdCRe='podman container run -it --rm --entrypoint /bin/bash'
alias pdCs='podman container start'
alias pdCss='podman container stats'
alias pdCx='podman container stop'
alias pdCtop='podman container top'
alias pdCP='podman container unpause'
alias pdCup='podman container update'
alias pdCw='podman container wait'

## Image (I)
alias pdI='podman image'
alias pdIb='podman image build'
alias pdIh='podman image history'
alias pdIim='podman image import'
alias pdIin='podman image inspect'
alias pdIls='podman image ls'
alias pdIpr='podman image prune'
alias pdIpl='podman image pull'
alias pdIph='podman image push'
alias pdIrm='podman image rm'
alias pdIsv='podman image save'
alias pdIt='podman image tag'

## Volume (V)
alias pdV='podman volume'
alias pdVin='podman volume inspect'
alias pdVls='podman volume ls'
alias pdVpr='podman volume prune'
alias pdVrm='podman volume rm'

## Network (N)
alias pdN='podman network'
alias pdNs='podman network connect'
alias pdNx='podman network disconnect'
alias pdNin='podman network inspect'
alias pdNls='podman network ls'
alias pdNpr='podman network prune'
alias pdNrm='podman network rm'

## System (Y)
alias pdY='podman system'
alias pdYdf='podman system df'
alias pdYpr='podman system prune'

## Stack (K)
alias pdK='podman stack'
alias pdKls='podman stack ls'
alias pdKps='podman stack ps'
alias pdKrm='podman stack rm'

## Swarm (W)
alias pdW='podman swarm'

## CleanUp (rm)
# Clean up exited containers (podman < 1.13)
alias pdrmC='podman rm $(docker ps -qaf status=exited)'
# Clean up dangling images (podman < 1.13)
alias pdrmI='podman rmi $(docker images -qf dangling=true)'
# Clean up dangling volumes (podman < 1.13)
alias pdrmV='podman volume rm $(docker volume ls -qf dangling=true)'


# podman Machine (m)
alias pdm='podman-machine'
alias pdma='podman-machine active'
alias pdmcp='podman-machine scp'
alias pdmin='podman-machine inspect'
alias pdmip='podman-machine ip'
alias pdmk='podman-machine kill'
alias pdmls='podman-machine ls'
alias pdmpr='podman-machine provision'
alias pdmps='podman-machine ps'
alias pdmrg='podman-machine regenerate-certs'
alias pdmrm='podman-machine rm'
alias pdms='podman-machine start'
alias pdmsh='podman-machine ssh'
alias pdmst='podman-machine status'
alias pdmS='podman-machine restart'
alias pdmu='podman-machine url'
alias pdmup='podman-machine upgrade'
alias pdmv='podman-machine version'
alias pdmx='podman-machine stop'

# podman Compose (c)
alias pdc='podman compose'
alias pdcb='podman compose build'
alias pdcB='podman compose build --no-cache'
alias pdcd='podman compose down'
alias pdce='podman compose exec'
alias pdck='podman compose kill'
alias pdcl='podman compose logs'
alias pdcls='podman compose ps'
alias pdcp='podman compose pause'
alias pdcP='podman compose unpause'
alias pdcpl='podman compose pull'
alias pdcph='podman compose push'
alias pdcps='podman compose ps'
alias pdcr='podman compose run'
alias pdcR='podman compose run --rm'
alias pdcrm='podman compose rm'
alias pdcs='podman compose start'
alias pdcsc='podman compose scale'
alias pdcS='podman compose restart'
alias pdcu='podman compose up'
alias pdcU='podman compose up -d'
alias pdcv='podman compose version'
alias pdcx='podman compose stop'
