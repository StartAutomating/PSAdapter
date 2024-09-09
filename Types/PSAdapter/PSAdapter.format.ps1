Write-FormatView -TypeName PSAdapter -Action {
    Write-FormatViewExpression -ScriptBlock {
        if ($_.BaseType.Name -match 'CmdletAdapter' -or $_ -is [IO.FileInfo]) {
            $_.Fullname
        } else {
            $_.Name
        }        
    }
} -GroupByProperty PSAdapterType
