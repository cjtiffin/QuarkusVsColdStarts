#!/bin/sh -ex

go get github.com/aws/aws-lambda-go/lambda
go get github.com/aws/aws-lambda-go/events
GOOS=linux GOARCH=amd64 go build -o testLambda TestLambda.go
zip testLambda.zip testLambda > /dev/null
