namespace :geocode do
  task :checkout do
    sh "svn checkout --quiet https://svn.xlsuite.org/internal/zip-code-databases"
  end

  desc "Importing geocodes"
  task :import => %w(environment geocode:checkout) do
    rows_per_sql_statement = 5000

    Geocode.transaction do
      puts "Loading USA postal codes..."
      usa_csv = CSV.open("zip-code-databases/us-zip-codes/5-digit Premium.csv", 'r')
      usa_csv.shift # first row is the headers

      values = []
      insert_into = "INSERT INTO geocodes (`city`, `city_type`, `state`, `country`, `latitude`, `longitude`, `zip`, `zip_type`, `area_code`) VALUES"

      country = AddressContactRoute::UNITED_STATES
      usa_csv.each_with_index do |row, i|
        # Escaping apostrophes for cities
        row[2] = row[2].gsub("'", "\\\\'")
        values << "('#{row[2]}', '#{row[3]}', '#{row[5]}', '#{country}', #{row[7]}, #{row[8]}, '#{row[0]}', '#{row[1]}', '#{row[6]}')"
        if (i%rows_per_sql_statement == 0 && i !=0)
          Geocode.connection.execute(insert_into + values.join(","))
          puts "Rows #{i-rows_per_sql_statement} to #{i} imported"
          values.clear
        end
      end

      if !values.blank?
        Geocode.connection.execute(insert_into + values.join(","))
        values.clear
      end

      puts "Loading Canadian postal codes..."
      canada_csv = CSV.open("zip-code-databases/canada-postal-codes/6-digit Premium.csv", 'r')
      canada_csv.shift # first row is the headers

      puts "Updating Geocodes table..."

      values = []
      insert_into = "INSERT INTO geocodes (`city`, `city_type`, `state`, `country`, `latitude`, `longitude`, `zip`) VALUES"

      country = AddressContactRoute::CANADA
      canada_csv.each_with_index do |row, i|
        # Escaping apostrophes for cities
        row[1] = row[1].gsub("'", "\\\\'")
        values << "('#{row[1]}', '#{row[2]}', '#{row[4]}', '#{country}', #{row[5]}, #{row[6]}, '#{row[0].gsub(" ", "").upcase}')"
        if (i%rows_per_sql_statement == 0 && i !=0)
          Geocode.connection.execute(insert_into + values.join(","))
          puts "Rows #{i-rows_per_sql_statement} to #{i} imported"
          values.clear
        end
      end

      if !values.blank?
        Geocode.connection.execute(insert_into + values.join(","))
        values.clear
      end
    end
  end
end
