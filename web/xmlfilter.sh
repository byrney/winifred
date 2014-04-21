#!/bin/bash

# if no query supplied match all
match=${1:-'.'}

#
# header
#
cat << EOH
<?xml version="1.0"?>
<items>
EOH

# 
# body filtered by query
#
cat << EOB | grep -i "$match"

  <item uid="r53" arg="route53" autocomplete="r53" > <title>Amazon r53 Console</title> <subtitle>Route 53 DNS</subtitle> <icon >route53.png</icon> </item>

  <item uid="ec2" arg="ec2" autocomplete="ec2" > <title>Amazon EC2 Console</title> <subtitle>Elastic Compute</subtitle> <icon >ec2.png</icon> </item>

  <item uid="iam" arg="iam" autocomplete="iam" > <title>Amazon IAM Console</title> <subtitle>Identity Management</subtitle> <icon >iam.png</icon> </item>

  <item uid="vpc" arg="vpc" autocomplete="vpc" > <title>Amazon VPC Console</title> <subtitle>Virtual Provate Cloud</subtitle> <icon >vpc.png</icon> </item>

  <item uid="rds" arg="rds" autocomplete="rds" > <title>Amazon RDS Console</title> <subtitle>Relational Database</subtitle> <icon >rds.png</icon> </item>

EOB

#
# footer
#
cat << EOF
</items>
EOF


