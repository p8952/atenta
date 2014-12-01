Sequel.migration do

	change do
		create_table :attacks do
			primary_key :id
			DateTime :timestamp
			String :source_ip
			String :target_ip
		end
	end

end
