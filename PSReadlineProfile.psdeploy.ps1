Deploy PSReadlineProfile {
    By FileSystem Profile {
        FromSource '_output\PSReadlineProfile.ps1'
        To '\\localhost\c$\Users\thbarratt\Documents\WindowsPowerShell\PSReadlineProfile.ps1',
           '\\localhost\c$\Users\thbarratt\Documents\PowerShell\PSReadlineProfile.ps1'
    }
}