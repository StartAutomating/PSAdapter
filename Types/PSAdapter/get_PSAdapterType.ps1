if ($this -is [Management.Automation.PSModuleInfo]) {
    'Module'
} 
elseif ($this -is [type]) {
    'Type'
}
elseif ($this -is [System.IO.FileInfo]) {
    'File'
}