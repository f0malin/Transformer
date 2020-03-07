#!/bin/bash
docker build -f Dockerfile_transformer -t api6.hukaa.com:5000/hukaa_transformer:1.2 .
docker push api6.hukaa.com:5000/hukaa_transformer:1.2
