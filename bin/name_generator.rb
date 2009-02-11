last_names = File.open("dist.all.last", "rb") {|f| f.read}
male_names = File.open("dist.male.first", "rb") {|f| f.read}
female_names = File.open("dist.female.first", "rb") {|f| f.read}

def extractor(list)
  list.scan(/^\w+/)
end

last_names = extractor(last_names).map(&:capitalize)
male_names = extractor(male_names).map(&:capitalize)
female_names = extractor(female_names).map(&:capitalize)
middle_initials = ("A".."Z").to_a

account = Account.find(1)
count = ARGV[0].to_i
puts "Generating #{count} names"
count.times do
  n = Name.new
  n.last = last_names[rand(last_names.size)]
  if rand() < 0.46 then
    n.first = male_names[rand(male_names.size)]
  else
    n.first = female_names[rand(female_names.size)]
  end 

  n.middle = middle_initials[rand(26)] if rand() < 0.45
  Party.transaction do
    party = account.parties.create!(:name => n)
    party.main_email.update_attributes(:address => "#{n.first}.#{n.last}.#{party.id}@hotmail.com".downcase)
    party.main_phone.update_attributes(:number => sprintf("%03d.%03d.%04d", rand(1000), rand(1000), rand(10000)))
  end

  puts n.to_s
end
