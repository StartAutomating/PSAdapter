Write-FormatView -TypeName PSAdapter -Action {
    Write-FormatViewExpression -ScriptBlock {
        if ($_.BaseType.Name -match 'CmdletAdapter') {
            $_.Fullname
        } else {
            $_.Name
        }        
    }
}
