ActiveRecord::Schema.define(:version => 0) do
  create_table :places, :force => true do |t|
    t.column :name, :string
  end
    
  create_table :things, :force => true do |t|
    t.column :place_id, :integer
  end
    
  create_table :tags, :force => true do |t|
    t.column :name, :string
  end

  create_table :taggings, :force => true do |t|
    t.column :tag_id, :integer
    t.column :taggable_id, :integer
    t.column :taggable_type, :string
  end

  create_table :places_from, :force => true do |t|
    t.column :name, :string
  end
end
