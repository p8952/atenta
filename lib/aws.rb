@ec2 = AWS::EC2.new(
	access_key_id: ENV['AWS_ACCESS_KEY'],
	secret_access_key: ENV['AWS_SECRET_KEY']
)

def start_honeypots
	@ec2.regions.each do |region|
		start_instance(region.name)
	end
end

def list_honeypots
	list_instances.each do |instance|
		puts "Active Honeypot: #{instance.id}"
	end
end

def stop_honeypots
	list_instances.each do |instance|
		delete_instance(instance)
	end
end

def start_instance(region)
	AWS.config(region: region)
	key_pair = @ec2.key_pairs.create("atenta-#{Time.now.to_i}")
	ami_id = @ec2.images.filter('name', 'RHEL-7.0_GA_HVM-x86_64*').to_a.sort_by(&:name).last.id
	instance = @ec2.instances.create(
		image_id: ami_id,
		instance_type: 't2.micro',
		count: 1,
		security_groups: 'default',
		key_pair: key_pair
	)
	puts "Starting Honeypot: #{instance.id}"
	sleep 5 while instance.status == :pending
	instance.add_tag('atenta')
end

def list_instances
	instances = []
	@ec2.regions.each do |region|
		@ec2.regions[region.name].instances.each do |instance|
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
	puts "Deleting Honeypot: #{instance.id}"
	instance.key_pair.delete
	instance.delete
end
