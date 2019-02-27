#!/bin/bash

aws ec2 describe-security-groups \
    --group-names 'Default' \
    --query 'SecurityGroups[0].OwnerId' \
    --output text

