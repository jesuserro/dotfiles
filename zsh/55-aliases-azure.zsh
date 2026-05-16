# =============================================================================
# Azure CLI aliases (read-only / convenience)
# =============================================================================

alias azlogin='az login'
alias azacct='az account show --output table'
alias azsubs='az account list --output table'
alias azsetsub='az account set --subscription'
alias azgroups='az group list --output table'
alias azacr='az acr list --output table'
alias azcapps='az containerapp list --output table'
alias azexts='az extension list --output table'
alias azcaext='az extension show --name containerapp --output table'
alias azlocs='az account list-locations --output table'
