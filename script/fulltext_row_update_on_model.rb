require 'main'

Main do
  argument("model_name"){required}
  def run
    model_name = params["model_name"].value
    class_name = model_name.classify
    klass = class_name.constantize
    has_account_id = klass.column_names.include?("account_id")
    select_param = ["id"]
    fields = ["subject_id", "subject_type", "deletion"]
    if has_account_id
      select_param << "account_id"
      fields << "account_id"
    end
    fields_in_string = fields.map{|e| "`" + e + "`"}.join(",")
    values = nil
    if has_account_id
      klass.find(:all, :select => select_param.join(",")).each_slice(1000) do |objects|
        values = []
        objects.each do |object|
          values << "(#{object.id}, '#{class_name}', 0, #{object.account_id})"
        end
        ActiveRecord::Base.connection.execute("INSERT INTO fulltext_row_updates(#{fields_in_string}) VALUES #{values.join(",")}")
      end
    else
      klass.find(:all, :select => select_param.join(",")).each_slice(1000) do |objects|
        values = []
        objects.each do |object|
          values << "(#{object.id}, '#{class_name}', 0)"
        end
        ActiveRecord::Base.connection.execute("INSERT INTO fulltext_row_updates(#{fields_in_string}) VALUES #{values.join(",")}")
      end
    end
  end
end
