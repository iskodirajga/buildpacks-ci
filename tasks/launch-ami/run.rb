#!/usr/bin/env ruby

require 'json'

ami_json = File.read('edge-ami/output.json')
ami_data = JSON.parse(ami_json)
ami_image_id = ami_data['ImageId']

puts 'Creating EC2 instance'

create_instance_output = `aws ec2 run-instances --image-id #{ami_image_id} --subnet-id subnet-106cd948 --associate-public-ip-address`
puts create_instance_output

File.write('launched-instances/instance.json', create_instance_output)

new_instance_data = JSON.parse(create_instance_output)
new_instance_id = new_instance_data['Instances'].first['InstanceId']

puts "Instance #{new_instance_id} created, waiting for it to be running"

puts "aws ec2 wait instance-running --instance-ids #{new_instance_id}"
puts 'Waiting...'
puts `aws ec2 wait instance-running --instance-ids #{new_instance_id}`
