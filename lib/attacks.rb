def populate_attacks
	@geoip = GeoIP.new('db/GeoIP.dat')
	Dir.glob("#{File.dirname(File.dirname(__FILE__))}/honeypots/logs/sshd-*.log") do |log|
		target_ip = File.basename(log, '.log').split('-')[1]
		File.read(log).lines.each do |line|
			check_line(target_ip, line)
		end
	end
end

def clear_attacks
	Attacks.map(&:delete)
end

def check_line(target_ip, line)
	regexes = [
		/Connection closed by .* \[preauth\]/,
		/Did not receive identification string from/,
		/Invalid user .* from/,
		/Received disconnect from .* Bye Bye \[preauth\]/
	]
	regexes.each do |regex|
		record_line(target_ip, line) if line =~ regex
	end
end

def record_line(target_ip, line)
	begin
		timestamp = Time.parse((/^[A-Z][a-z]{2} ( \d|\d{2}) \d{2}:\d{2}:\d{2}/).match(line).to_s)
		source_ip = (/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/).match(line).to_s
		Attacks.find_or_create(
			timestamp: timestamp,
			source_ip: source_ip,
			target_ip: target_ip,
			source_geo: @geoip.country(source_ip)[:country_code2].downcase,
			target_geo: @geoip.country(target_ip)[:country_code2].downcase
		)
	rescue => e
		puts e
	end
end
