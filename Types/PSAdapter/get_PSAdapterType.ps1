if ($_ -is [Management.Automation.PSModuleInfo]) {
    'Module'
} 
elseif ($_ -is [type]) {
    'Type'
}
elseif ($_ -is [System.IO.FileInfo]) {
    'File'
}