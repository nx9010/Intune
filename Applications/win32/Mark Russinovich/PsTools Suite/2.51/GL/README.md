## PsTools Suite 2.51

**Description**
>PSTools is a powerful suite of command line tools that can be leveraged by IT System Administrators.

**Publisher:** Mark Russinovich
**App Version:** 2.51
**Information URL:** https://learn.microsoft.com/en-us/sysinternals/downloads/pstools
**Privacy URL:** 

**Commands:**
- **Install**
	`Deploy-Application.exe ".\PsTools Suite_2.51.ps1" -DeploymentType 'Install' -DeployMode 'Silent'`
- **Uninstall**:
	`Deploy-Application.exe ".\PsTools Suite_2.51.ps1" -DeploymentType 'Uninstall' -DeployMode 'Silent'`

**Detection Rules:**
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PSTools
