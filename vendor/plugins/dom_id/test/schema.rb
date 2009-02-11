ActiveRecord::Schema.define(:version => 1) do
  
  create_table :things do |t|
    t.column :name,   :string
  end
    
  create_table :people_things do |t|
    t.column :name,   :string
  end
    
end
