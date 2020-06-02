#!/bin/sh -ex

mvn clean package -Dnative -Dquarkus.native.container-build=true  > /dev/null
