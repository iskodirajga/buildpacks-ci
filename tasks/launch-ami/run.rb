#!/usr/bin/env ruby

require 'json'


ami_json = File.read('edge-ami/output.json')
ami_data = JSON.parse(ami_json)
ami_image_id = ami_data['ImageId']

puts 'Creating EC2 instance'

puts `aws ec2 run-instances --image-id #{ami_image_id} --subnet-id subnet-106cd948`