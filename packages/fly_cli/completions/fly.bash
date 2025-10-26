# Fly CLI bash completion script

_fly_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Global options
    local global_opts=""

    # Commands
    local commands=""

    # Default completion
    case "${prev}" in
        --output)
            COMPREPLY=( $(compgen -W "human json" -- "${cur}") )
            return 0
            ;;
    esac
    
    COMPREPLY=( $(compgen -W "${global_opts}" -- "${cur}") )
}

complete -F _fly_completion fly
