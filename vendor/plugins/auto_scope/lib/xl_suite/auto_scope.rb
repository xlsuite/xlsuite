module XlSuite
  module AutoScope
    def self.extended(base)
      base.write_inheritable_attribute("auto_scope_options", Hash.new)
    end

    def auto_scope(scopes)
      my_class = self
      scopes.each_pair do |scope_name, options|
        read_inheritable_attribute("auto_scope_options")[scope_name] = options
        read_inheritable_attribute("auto_scope_options").stringify_keys!

        method_body = <<-EOF
          def self.auto_scope_options(scope_name)
            scope_options = read_inheritable_attribute("auto_scope_options")[scope_name].dup
            evaluate_auto_scope_values!(scope_options)
            scope_options
          end

          def self.#{scope_name}
            returning(Object.new) do |proxy|
              proxy.instance_variable_set(:@scope, current_scoped_methods || {})
              class << proxy
                def build(args = {})

                  # create_scope enforced
                  create_scope = instance_variable_get(:@scope)[:create] || {}
                  args.merge!(create_scope)
                  scope_options = #{class_name}.auto_scope_options("#{scope_name}")[:create] || {}

                  # auto_scope enforced
                  args.merge!(scope_options)

                  #{class_name}.new(args)
                end

                def method_missing(method, *args)
                  scope_options = #{class_name}.auto_scope_options("#{scope_name}")
                  #{class_name}.with_scope(instance_variable_get(:@scope)) do
                    #{class_name}.with_scope(scope_options) do
                      #{class_name}.send(method, *args)
                    end
                  end
                end
              end
            end
          end
        EOF

        class_eval method_body
      end
    end

    def evaluate_auto_scope_values!(root)
      root.each_pair do |key, value|
        evaluate_auto_scope_values!(value) if value.kind_of?(Hash)
        case
        when value.respond_to?(:collect!)
          value.collect! do |value|
            value.respond_to?(:call) ? value.call : value
          end
        when value.respond_to?(:call)
          root[key] = value.call
        end
      end
    end
  end
end
