#!/bin/bash
# Fly CLI bash completion script

_fly_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    local commands="create add doctor version schema context"
    
    # Add subcommands
    local add_commands="screen service"
    
    # Global options
    local global_opts="--help --version --verbose --quiet --output --plan"
    
    # Command-specific options
    local create_opts="--template --organization --platforms --interactive --from-manifest"
    local add_opts="--feature --type --with-viewmodel --with-tests --with-mocks --base-url"
    local schema_opts="--command"
    local context_opts="--include-dependencies --include-structure --include-conventions"
    
    # Template options
    local templates="minimal riverpod"
    
    # Platform options
    local platforms="ios android web macos windows linux"
    
    # Output format options
    local output_formats="human json"
    
    case ${COMP_CWORD} in
        1)
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            return 0
            ;;
        2)
            case ${prev} in
                add)
                    COMPREPLY=( $(compgen -W "${add_commands}" -- ${cur}) )
                    return 0
                    ;;
                create)
                    COMPREPLY=( $(compgen -W "${create_opts}" -- ${cur}) )
                    return 0
                    ;;
                schema)
                    COMPREPLY=( $(compgen -W "${schema_opts}" -- ${cur}) )
                    return 0
                    ;;
                context)
                    COMPREPLY=( $(compgen -W "${context_opts}" -- ${cur}) )
                    return 0
                    ;;
            esac
            ;;
        3)
            case ${COMP_WORDS[1]} in
                add)
                    case ${COMP_WORDS[2]} in
                        screen|service)
                            COMPREPLY=( $(compgen -W "${add_opts}" -- ${cur}) )
                            return 0
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac
    
    # Handle specific option values
    case ${prev} in
        --template)
            COMPREPLY=( $(compgen -W "${templates}" -- ${cur}) )
            return 0
            ;;
        --platforms)
            COMPREPLY=( $(compgen -W "${platforms}" -- ${cur}) )
            return 0
            ;;
        --output)
            COMPREPLY=( $(compgen -W "${output_formats}" -- ${cur}) )
            return 0
            ;;
        --type)
            local service_types="api repository storage analytics"
            COMPREPLY=( $(compgen -W "${service_types}" -- ${cur}) )
            return 0
            ;;
    esac
    
    # Default completion
    COMPREPLY=( $(compgen -W "${global_opts}" -- ${cur}) )
    return 0
}

complete -F _fly_completion fly
