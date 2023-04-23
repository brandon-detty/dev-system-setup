function refresh-path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
}

winget add microsoft.windowsterminal

winget add "microsoft powertoys"

ssh-keygen -t ecdsa -b 521

winget add git.git
refresh-path
git config --global init.defaultBranch main
git config --global user.name "Brandon Detty"
git config --global user.email "113217431+brandon-detty@users.noreply.github.com"

winget add "node.js lts"

winget add microsoft.visualstudio.2022.community

winget add golang.go.1.20
refresh-path
mkdir ~\go\src\github.com
mkdir ~\source\go
New-Item -ItemType Junction -Path ~\go\src\github.com\brandon-detty -Target ~\source\go
