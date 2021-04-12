# auto-ec2
This script creates an ec2 instance with an attached ebs using AWS Cloudformation template.

What you will need:
- an IAM user created in AWS
- aws cli installed (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- running 'aws configure' with your access key id and access key and region (https://docs.aws.amazon.com/cli/latest/reference/configure/)
- a key-pair file in .pem foramt which should be copied in the running directory
- the id of the vpc and subnet where you want to put the instance

How to run:

./createinstance name_of_the_instance instance_type availability_zone key_name security_group_name ebs_volume_size ebs_volume_name vpc_id subnet_id

Example: 

./createinstance myinstance r5.large eu-west-1 mykey mysecuritygroup 64 myvolume vpc-1111111111111 subnet-1111111

You can desstroy the created resources on AWS console, using the Cloudformation service. 
