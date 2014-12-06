def start_honeypots
	ec2.regions.peach do |region|
		start_instance(region.name)
	end
end

def list_honeypots
	list_instances.peach do |instance|
		puts "Active Honeypot: #{instance.id} #{instance.availability_zone} #{instance.ip_address}"
	end
end

def harvest_honeypots
	list_instances.peach do |instance|
		collect_logs(instance)
	end
end

def stop_honeypots
	list_instances.peach do |instance|
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
	begin
		instance = ec2(region).instances.create(
			image_id: ami_id,
			instance_type: 't2.micro',
			count: 1,
			security_group_ids: security_group.id,
			key_pair: key_pair,
			user_data: norequiretty.join("\n")
		)
		instance.add_tag('atenta')
		sleep 5 while instance.status != :running
	rescue
		instance.key_pair.delete
		instance.delete
		puts "Failed To Start Honeypot: #{instance.id} #{instance.availability_zone}"
		exit
	end
	key_file = "#{File.dirname(File.dirname(__FILE__))}/honeypots/keys/#{instance.id}.pem"
	File.write(key_file, key_pair.private_key)
	File.chmod(0400, key_file)
	puts "Started Honeypot: #{instance.id} #{instance.availability_zone}"

	configure_instance(instance)
end

def configure_instance(instance)
	return if instance.tags.include?('configured')
	key_file = File.read("#{File.dirname(File.dirname(__FILE__))}/honeypots/keys/#{instance.id}.pem")
	begin
		Net::SSH.start(instance.ip_address, 'ec2-user', key_data: key_file) do |ssh|
			ssh.exec!('sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime')
			ssh.exec!('sudo sed -i "s/permissive/disabled/g" /etc/selinux/config')
			ssh.exec!('sudo setenforce Permissive')
			ssh.exec!('echo "if \$programname == \'sshd\' then /home/ec2-user/sshd.log" | sudo tee /etc/rsyslog.d/sshd.conf')
			ssh.exec!('sudo service rsyslog restart')
			ssh.exec!('sudo sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config')
			ssh.exec!('sudo service sshd restart')
		end
	rescue
		puts "Error Configuring Honeypot: #{instance.id} #{instance.availability_zone}... Retrying"
		sleep 5
		retry
	end
	instance.add_tag('configured')
	puts "Configured Honeypot: #{instance.id} #{instance.availability_zone}"
end

def list_instances
	instances = []
	ec2.regions.peach do |region|
		ec2.regions[region.name].instances.peach do |instance|
			instance.tags.peach do |key, _val|
				next if key != 'atenta'
				next if instance.status != :running
				instances << instance
			end
		end
	end
	instances
end

def collect_logs(instance)
	key_file = File.read("#{File.dirname(File.dirname(__FILE__))}/honeypots/keys/#{instance.id}.pem")
	Net::SCP.start(instance.ip_address, 'ec2-user', key_data: key_file) do |scp|
		scp.download!('/home/ec2-user/sshd.log', "honeypots/logs/sshd-#{instance.ip_address}.log")
	end
	puts "Harvested Honeypot: #{instance.id} #{instance.availability_zone}"
end

def delete_instance(instance)
	return if instance.status != :running
	key_file = "#{File.dirname(File.dirname(__FILE__))}/honeypots/keys/#{instance.id}.pem"
	File.delete(key_file)
	instance.key_pair.delete
	instance.delete
	puts "Deleted Honeypot: #{instance.id} #{instance.availability_zone}"
end
