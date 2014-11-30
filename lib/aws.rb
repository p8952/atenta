def start_honeypots
	ec2.regions.each do |region|
		start_instance(region.name)
	end
	list_instances.each do |instance|
		configure_instance(instance)
	end
end

def list_honeypots
	list_instances.each do |instance|
		puts "Active Honeypot: #{instance.id} #{instance.availability_zone} #{instance.ip_address} " + \
		"(ssh -i keys/#{instance.id}.pem ec2-user@#{instance.ip_address})"
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
	# I hate PTYs
	norequiretty = []
	norequiretty << '#!/usr/bin/env bash'
	norequiretty << 'sed -i -e \'s/^Defaults.*requiretty/#Defaults requiretty/g\' /etc/sudoers'

	security_group = nil
	if ec2(region).security_groups.filter('group-name', 'atenta').first.nil?
		security_group = ec2(region).security_groups.create('atenta')
		security_group.authorize_ingress(:any, '0.0.0.0/0')
	else
		security_group = ec2(region).security_groups.filter('group-name', 'atenta').first
	end

	ami_id = ec2(region).images.filter('name', 'RHEL-7.0*HVM*x86_64*').to_a.sort_by(&:name).last.id
	key_pair = ec2(region).key_pairs.create("atenta-#{Time.now.to_i}")
	instance = ec2(region).instances.create(
		image_id: ami_id,
		instance_type: 't2.micro',
		count: 1,
		security_group_ids: security_group.id,
		key_pair: key_pair,
		user_data: norequiretty.join("\n")
	)
	begin
		sleep 5 while instance.status != :running
		instance.add_tag('atenta')
	rescue
		instance.key_pair.delete
		instance.delete
	end
	key_file = "#{File.dirname(File.dirname(__FILE__))}/keys/#{instance.id}.pem"
	File.write(key_file, key_pair.private_key)
	File.chmod(0400, key_file)
	puts "Started Honeypot: #{instance.id} #{instance.availability_zone}"
end

def configure_instance(instance)
	return if instance.tags.include?('configured')
	key_file = File.read("#{File.dirname(File.dirname(__FILE__))}/keys/#{instance.id}.pem")
	begin
		Net::SSH.start(instance.ip_address, 'ec2-user', key_data: key_file) do |ssh|
			ssh.exec!('sudo sed -i "s/permissive/disabled/g" /etc/selinux/config')
			ssh.exec!('sudo setenforce Permissive')
			ssh.exec!('echo "if \$programname == \'sshd\' then /home/ec2-user/sshd.log" | sudo tee /etc/rsyslog.d/sshd.conf')
			ssh.exec!('sudo service rsyslog restart')
			ssh.exec!('sudo sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config')
			ssh.exec!('sudo service sshd restart')
		end
	rescue
		sleep 5
		retry
	end
	instance.add_tag('configured')
end

def list_instances
	instances = []
	ec2.regions.each do |region|
		ec2.regions[region.name].instances.each do |instance|
			instance.tags.each do |key, _val|
				next if key != 'atenta'
				next if instance.status != :running
				instances << instance
			end
		end
	end
	instances
end

def delete_instance(instance)
	return if instance.status != :running
	key_file = "#{File.dirname(File.dirname(__FILE__))}/keys/#{instance.id}.pem"
	File.delete(key_file)
	instance.key_pair.delete
	instance.delete
	puts "Deleted Honeypot: #{instance.id} #{instance.availability_zone}"
end
