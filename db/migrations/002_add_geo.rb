Sequel.migration do

	change do
		add_column :attacks, :source_geo, String
		add_column :attacks, :target_geo, String
	end

end
