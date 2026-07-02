
$env:PATH = "D:\Program Files\Go\bin;" + $env:PATH
$env:GOROOT = "D:\Program Files\Go"
$env:GOPATH = "$env:USERPROFILE\go"


go env -w GOPROXY=https://goproxy.cn,direct
go env -w GOSUMDB=sum.golang.google.cn


cd e:\github\DailyAwarenessApp\backend


go mod tidy


go build -o api.exe ./cmd/api


.\api.exe