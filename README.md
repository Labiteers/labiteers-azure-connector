Best approach
=============

Store the script in GitHub and run it directly in Cloud Shell

Commit your script to a GitHub repository.

In Azure Cloud Shell, you can download and run it in one command:

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/<username>/<repo>/main/LabiteersAppSetup.ps1" -OutFile "./LabiteersAppSetup.ps1"
.\LabiteersAppSetup.ps1


✅ Advantages:

Always runs the latest version.

No local copy needed.

Great for team sharing and version control.


https://raw.githubusercontent.com/<GitHubUsername>/<RepositoryName>/<BranchName>/<FilePath>

