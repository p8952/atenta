def start_honeypots
	ec2.regions.each do |region|
		start_instance(region.name)
	end
end

def list_honeypots
	list_instances.each do |instance|
		puts "Active Honeypot: #{instance.id} #{instance.availability_zone} #{instance.ip_address}"
	end
end

def stop_honeypots
	list_instances.each do |instance|
		delete_instance(instance)
	end
end

def ec2(region = 'us-east-1')
	ec2 = AWS::EC2.new(
		access_key_id: ENV['AWS_ACCESS_KEY'],
		secret_access_key: ENV['AWS_SECRET_KEY'],
		region: region
	)
	ec2
end

def start_instance(region)
	ami_id = ec2(region).images.filter('name', 'RHEL-7.0*HVM*x86_64*').to_a.sort_by(&:name).last.id
	key_pair = ec2(region).key_pairs.create("atenta-#{Time.now.to_i}")
	instance = ec2(region).instances.create(
		image_id: ami_id,
		instance_type: 't2.micro',
		count: 1,
		security_groups: 'default',
		key_pair: key_pair
	)
	begin
		sleep 5 while instance.status == :pending
		instance.add_tag('atenta')
	rescue
		instance.key_pair.delete
		instance.delete
	end
	key_file = "#{File.dirname(File.dirname(__FILE__))}/keys/#{instance.id}.pem"
	File.write(key_file, key_pair.private_key)
	File.chmod(0400, key_file)
	puts "Started Honeypot: #{instance.id} #{instance.availability_zone} #{instance.ip_address}"
end

def list_instances
	instances = []
	ec2.regions.each do |region|
		ec2.regions[region.name].instances.each do |instance|
			instance.tags.each do |key, _val|
				next if key != 'atenta'
				next if instance.status == :terminated
				instances << instance
			end
		end
	end
	instances
end

def delete_instance(instance)
	key_file = "#{File.dirname(File.dirname(__FILE__))}/keys/#{instance.id}.pem"
	File.delete(key_file)
	instance.key_pair.delete
	instance.delete
	puts "Deleted Honeypot: #{instance.id} #{instance.availability_zone} #{instance.ip_address}"
end
