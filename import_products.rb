require "fastercsv"
require "uri"
require "net/http"

raise "Missing domain name on command line" if ARGV.empty?
account = Domain.find_by_name(ARGV.unshift).account

Product.transaction do
  FasterCSV.parse(STDIN, :headers => true) do |row|
    # Name,Picture URL,Unit Price,Description,Product No,Wholesale Price,Supplier Name,Categories

    product = account.products.build

    product.name            = row[0]
    product.retail_price    = row[2].to_money
    product.description     = row[3]
    product.sku             = row[4]
    product.wholesale_price = row[5].to_money
    product.save!

    product.categories = row[7].split(",").map do |name|
      account.product_categories.find_or_create_by_name(name)
    end.uniq

    print row[1]
    asset = nil
    Tempfile.open("image") do |data|
      data.write Net::HTTP.get(URI.parse(row[1]))
      data.rewind
      class << data
        def content_type
          "image/jpg"
        end

        def original_filename
          "thefile.jpg"
        end
      end

      puts "\t#{data.length}"
      asset = account.assets.create!(:uploaded_data => data, :filename => "#{product.name}.jpg", :title => product.name, :tag_list => "product")
    end unless row[1].blank?

    product.pictures << asset if asset
    puts product.sku
  end
end
