#!/bin/bash
#
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

function usage
{
 echo "usage is $0 [--help][-t user/repo:version]
where :
- help: is the current help
- t   : Tag the image built. Respect the tag format use by docker -t option.
"
}

if [ "p$1" = "p--help" ]
then
   usage
   exit
fi

if [ "p$1" = "p-t" ] && [ "p$2" != "" ]
then
   TAG="-t $2"
fi

if [ "$http_proxy" = "" ]
then
   echo "Currently, no proxy is set. Running docker without proxy"
   docker build $TAG .
   exit
fi

mkdir .tmp
awk '$0 ~ /RUN \/tmp\/proxy.sh/ { print "ENV http_proxy '"$http_proxy"'" }
     $0 ~ // { print $0 } ' Dockerfile > .tmp/Dockerfile
cp -rp files tmp .tmp/
docker build $TAG .tmp
rm -fr .tmp
