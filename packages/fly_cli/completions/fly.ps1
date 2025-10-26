# Fly CLI PowerShell completion script

Register-ArgumentCompleter -Native -CommandName fly -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    
    $completions = @()
    
    # Commands
    $commands = @('')
    
    # Global options
    $globalOptions = @()
    
    if ($wordToComplete -match '^[^-]') {
        # Complete commands
        $completions = $commands | Where-Object { $_ -like "$wordToComplete*" }
    } else {
        # Complete options
        $completions = $globalOptions | Where-Object { $_ -like "$wordToComplete*" }
    }
    
    return $completions
}
