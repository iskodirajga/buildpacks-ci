#!/usr/bin/env ruby

require 'json'

instance_json = File.read('launched-instances/instance.json')
instance_data = JSON.parse(instance_json)
instance_id = instance_data['Instances'].first['InstanceId']

puts `aws ec2 terminate-instances --instance-ids #{instance_id}`