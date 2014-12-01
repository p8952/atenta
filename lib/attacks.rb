def populate_attacks
	Dir.glob("#{File.dirname(File.dirname(__FILE__))}/honeypots/logs/sshd-*.log") do |log|
		File.read(log).lines.each do |line|
			check_line(line)
		end
	end
end

def clear_attacks
	Attacks.map(&:delete)
end

def check_line(line)
	regexes = [
		/Connection closed by .* \[preauth\]/,
		/Invalid user .* from/
	]

	regexes.each do |regex|
		record_line(line) if line =~ regex
	end
end

def record_line(line)
	timestamp = Time.parse((/^[A-Z][a-z]{2} \d{2} \d{2}:\d{2}:\d{2}/).match(line).to_s)
	source_ip = (/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/).match(line).to_s
	target_ip = (/\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3}/).match(line).to_s.gsub('-', '.')
	Attacks.create(
		timestamp: timestamp,
		source_ip: source_ip,
		target_ip: target_ip
	)
end
