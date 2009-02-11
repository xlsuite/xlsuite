require 'rexml/document'
require 'yaml'

module YAML
	def YAML.dump( obj, io = nil )
	  if obj.kind_of?(FeedTools::Feed) || obj.kind_of?(FeedTools::FeedItem)
	    # Dangit, you WILL NOT serialize these things.
	    obj.instance_variable_set("@xml_document", nil)
	    obj.instance_variable_set("@root_node", nil)
	    obj.instance_variable_set("@channel_node", nil)
	  end
    obj.to_yaml( io || io2 = StringIO.new )
    io || ( io2.rewind; io2.read )
	end
	
	def YAML.load( io )
		yp = parser.load( io )
	  if yp.kind_of?(FeedTools::Feed) || yp.kind_of?(FeedTools::FeedItem)
	    # No really, I'm serious, you WILL NOT deserialize these things.
	    yp.instance_variable_set("@xml_document", nil)
	    yp.instance_variable_set("@root_node", nil)
	    yp.instance_variable_set("@channel_node", nil)
	  end
	  yp
	end
end

module REXML # :nodoc:
  class LiberalXPathParser < XPathParser # :nodoc:
    
  private
  
    # Monkey Patch for Ruby 1.8.4
    def expr( path_stack, nodeset, context=nil )
      #puts "#"*15
      #puts "In expr with #{path_stack.inspect}"
      #puts "Returning" if path_stack.length == 0 || nodeset.length == 0
      node_types = ELEMENTS
      return nodeset if path_stack.length == 0 || nodeset.length == 0
      while path_stack.length > 0
        #puts "Path stack = #{path_stack.inspect}"
        #puts "Nodeset is #{nodeset.inspect}"
        case (op = path_stack.shift)
        when :document
          nodeset = [ nodeset[0].root_node ]
          #puts ":document, nodeset = #{nodeset.inspect}"

        when :qname
          #puts "IN QNAME"
          prefix = path_stack.shift
          name = path_stack.shift
          ns = @namespaces[prefix]
          ns = ns ? ns : ''
          nodeset.delete_if do |node|
            # FIXME: This DOUBLES the time XPath searches take
            ns = node.namespace( prefix ) if node.node_type == :element and ns == ''
            #puts "NS = #{ns.inspect}"
            #puts "node.node_type == :element => #{node.node_type == :element}"
            if node.node_type == :element
              #puts "node.name == #{name} => #{node.name == name}"
              if node.name.downcase == name.downcase
                #puts "node.namespace == #{ns.inspect} => #{node.namespace == ns}"
              end
            end
            !(node.node_type == :element and 
              node.name.downcase == name.downcase and 
              node.namespace == ns )
          end
          node_types = ELEMENTS

        when :any
          #puts "ANY 1: nodeset = #{nodeset.inspect}"
          #puts "ANY 1: node_types = #{node_types.inspect}"
          nodeset.delete_if { |node| !node_types.include?(node.node_type) }
          #puts "ANY 2: nodeset = #{nodeset.inspect}"

        when :self
          # This space left intentionally blank

        when :processing_instruction
          target = path_stack.shift
          nodeset.delete_if do |node|
            (node.node_type != :processing_instruction) or 
            ( target!='' and ( node.target != target ) )
          end

        when :text
          nodeset.delete_if { |node| node.node_type != :text }

        when :comment
          nodeset.delete_if { |node| node.node_type != :comment }

        when :node
          # This space left intentionally blank
          node_types = ALL

        when :child
          new_nodeset = []
          nt = nil
          for node in nodeset
            nt = node.node_type
            new_nodeset += node.children if nt == :element or nt == :document
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :literal
          literal = path_stack.shift
          if literal =~ /^\d+(\.\d+)?$/
            return ($1 ? literal.to_f : literal.to_i) 
          end
          return literal

        when :attribute
          new_nodeset = []
          case path_stack.shift
          when :qname
            prefix = path_stack.shift
            name = path_stack.shift
            for element in nodeset
              if element.node_type == :element
                for attribute_name in element.attributes.keys
                  if attribute_name.downcase == name.downcase
                    attrib = element.attribute( attribute_name,
                      @namespaces[prefix] )
                    new_nodeset << attrib if attrib
                  end
                end
              end
            end
          when :any
            #puts "ANY"
            for element in nodeset
              if element.node_type == :element
                new_nodeset += element.attributes.to_a
              end
            end
          end
          nodeset = new_nodeset

        when :parent
          #puts "PARENT 1: nodeset = #{nodeset}"
          nodeset = nodeset.collect{|n| n.parent}.compact
          #nodeset = expr(path_stack.dclone, nodeset.collect{|n| n.parent}.compact)
          #puts "PARENT 2: nodeset = #{nodeset.inspect}"
          node_types = ELEMENTS

        when :ancestor
          new_nodeset = []
          for node in nodeset
            while node.parent
              node = node.parent
              new_nodeset << node unless new_nodeset.include? node
            end
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :ancestor_or_self
          new_nodeset = []
          for node in nodeset
            if node.node_type == :element
              new_nodeset << node
              while ( node.parent )
                node = node.parent
                new_nodeset << node unless new_nodeset.include? node
              end
            end
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :predicate
          new_nodeset = []
          subcontext = { :size => nodeset.size }
          pred = path_stack.shift
          nodeset.each_with_index { |node, index|
            subcontext[ :node ] = node
            #puts "PREDICATE SETTING CONTEXT INDEX TO #{index+1}"
            subcontext[ :index ] = index+1
            pc = pred.dclone
            #puts "#{node.hash}) Recursing with #{pred.inspect} and [#{node.inspect}]"
            result = expr( pc, [node], subcontext )
            result = result[0] if result.kind_of? Array and result.length == 1
            #puts "#{node.hash}) Result = #{result.inspect} (#{result.class.name})"
            if result.kind_of? Numeric
              #puts "Adding node #{node.inspect}" if result == (index+1)
              new_nodeset << node if result == (index+1)
            elsif result.instance_of? Array
              #puts "Adding node #{node.inspect}" if result.size > 0
              new_nodeset << node if result.size > 0
            else
              #puts "Adding node #{node.inspect}" if result
              new_nodeset << node if result
            end
          }
          #puts "New nodeset = #{new_nodeset.inspect}"
          #puts "Path_stack  = #{path_stack.inspect}"
          nodeset = new_nodeset
=begin
          predicate = path_stack.shift
          ns = nodeset.clone
          result = expr( predicate, ns )
          #puts "Result = #{result.inspect} (#{result.class.name})"
          #puts "nodeset = #{nodeset.inspect}"
          if result.kind_of? Array
            nodeset = result.zip(ns).collect{|m,n| n if m}.compact
          else
            nodeset = result ? nodeset : []
          end
          #puts "Outgoing NS = #{nodeset.inspect}"
=end

        when :descendant_or_self
          rv = descendant_or_self( path_stack, nodeset )
          path_stack.clear
          nodeset = rv
          node_types = ELEMENTS

        when :descendant
          results = []
          nt = nil
          for node in nodeset
            nt = node.node_type
            results += expr( path_stack.dclone.unshift( :descendant_or_self ),
              node.children ) if nt == :element or nt == :document
          end
          nodeset = results
          node_types = ELEMENTS

        when :following_sibling
          #puts "FOLLOWING_SIBLING 1: nodeset = #{nodeset}"
          results = []
          for node in nodeset
            all_siblings = node.parent.children
            current_index = all_siblings.index( node )
            following_siblings = all_siblings[ current_index+1 .. -1 ]
            results += expr( path_stack.dclone, following_siblings )
          end
          #puts "FOLLOWING_SIBLING 2: nodeset = #{nodeset}"
          nodeset = results

        when :preceding_sibling
          results = []
          for node in nodeset
            all_siblings = node.parent.children
            current_index = all_siblings.index( node )
            preceding_siblings = all_siblings[ 0 .. current_index-1 ].reverse
            #results += expr( path_stack.dclone, preceding_siblings )
          end
          nodeset = preceding_siblings
          node_types = ELEMENTS

        when :preceding
          new_nodeset = []
          for node in nodeset
            new_nodeset += preceding( node )
          end
          #puts "NEW NODESET => #{new_nodeset.inspect}"
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :following
          new_nodeset = []
          for node in nodeset
            new_nodeset += following( node )
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :namespace
          new_set = []
          for node in nodeset
            new_nodeset << node.namespace if node.node_type == :element or node.node_type == :attribute
          end
          nodeset = new_nodeset

        when :variable
          var_name = path_stack.shift
          return @variables[ var_name ]

        # :and, :or, :eq, :neq, :lt, :lteq, :gt, :gteq
        when :eq, :neq, :lt, :lteq, :gt, :gteq, :and, :or
          left = expr( path_stack.shift, nodeset, context )
          #puts "LEFT => #{left.inspect} (#{left.class.name})"
          right = expr( path_stack.shift, nodeset, context )
          #puts "RIGHT => #{right.inspect} (#{right.class.name})"
          res = equality_relational_compare( left, op, right )
          #puts "RES => #{res.inspect}"
          return res

        when :div
          left = Functions::number(expr(path_stack.shift, nodeset, context)).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context)).to_f
          return (left / right)

        when :mod
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left % right)

        when :mult
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left * right)

        when :plus
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left + right)

        when :minus
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left - right)

        when :union
          left = expr( path_stack.shift, nodeset, context )
          right = expr( path_stack.shift, nodeset, context )
          return (left | right)

        when :neg
          res = expr( path_stack, nodeset, context )
          return -(res.to_f)

        when :not
        when :function
          func_name = path_stack.shift.tr('-','_')
          arguments = path_stack.shift
          #puts "FUNCTION 0: #{func_name}(#{arguments.collect{|a|a.inspect}.join(', ')})" 
          subcontext = context ? nil : { :size => nodeset.size }

          res = []
          cont = context
          nodeset.each_with_index { |n, i| 
            if subcontext
              subcontext[:node]  = n
              subcontext[:index] = i
              cont = subcontext
            end
            arg_clone = arguments.dclone
            args = arg_clone.collect { |arg| 
              #puts "FUNCTION 1: Calling expr( #{arg.inspect}, [#{n.inspect}] )"
              expr( arg, [n], cont ) 
            }
            #puts "FUNCTION 2: #{func_name}(#{args.collect{|a|a.inspect}.join(', ')})" 
            Functions.context = cont
            res << Functions.send( func_name, *args )
            #puts "FUNCTION 3: #{res[-1].inspect}"
          }
          return res

        end
      end # while
      #puts "EXPR returning #{nodeset.inspect}"
      return nodeset
    end
  
    # Monkey Patch for Ruby 1.8.2
    def internal_parse(path_stack, nodeset) # :nodoc:
      return nodeset if nodeset.size == 0 or path_stack.size == 0
      case path_stack.shift
      when :document
        return [ nodeset[0].root.parent ]

      when :qname
        prefix = path_stack.shift.downcase
        name = path_stack.shift.downcase
        n = nodeset.clone
        ns = @namespaces[prefix]
        ns = ns ? ns : ''
        n.delete_if do |node|
          if node.node_type == :element and ns == ''
            ns = node.namespace( prefix )
          end
          !(node.node_type == :element and
            node.name.downcase == name.downcase and node.namespace == ns )
        end
        return n

      when :any
        n = nodeset.clone
        n.delete_if { |node| node.node_type != :element }
        return n

      when :self
        # THIS SPACE LEFT INTENTIONALLY BLANK

      when :processing_instruction
        target = path_stack.shift
        n = nodeset.clone
        n.delete_if do |node|
          (node.node_type != :processing_instruction) or 
          ( !target.nil? and ( node.target != target ) )
        end
        return n

      when :text
        n = nodeset.clone
        n.delete_if do |node|
          node.node_type != :text
        end
        return n

      when :comment
        n = nodeset.clone
        n.delete_if do |node|
          node.node_type != :comment
        end
        return n

      when :node
        return nodeset
      
      when :child
        new_nodeset = []
        nt = nil
        for node in nodeset
          nt = node.node_type
          new_nodeset += node.children if nt == :element or nt == :document
        end
        return new_nodeset

      when :literal
        literal = path_stack.shift
        if literal =~ /^\d+(\.\d+)?$/
          return ($1 ? literal.to_f : literal.to_i) 
        end
        return literal
        
      when :attribute
        new_nodeset = []
        case path_stack.shift
        when :qname
          prefix = path_stack.shift
          name = path_stack.shift
          for element in nodeset
            if element.node_type == :element
              for attribute_name in element.attributes.keys
                if attribute_name.downcase == name.downcase
                  attrib = element.attribute( attribute_name,
                    @namespaces[prefix] )
                  new_nodeset << attrib if attrib
                end
              end
            end
          end
        when :any
          for element in nodeset
            if element.node_type == :element
              new_nodeset += element.attributes.to_a
            end
          end
        end
        return new_nodeset

      when :parent
        return internal_parse( path_stack,
          nodeset.collect{|n| n.parent}.compact )

      when :ancestor
        new_nodeset = []
        for node in nodeset
          while node.parent
            node = node.parent
            new_nodeset << node unless new_nodeset.include? node
          end
        end
        return new_nodeset

      when :ancestor_or_self
        new_nodeset = []
        for node in nodeset
          if node.node_type == :element
            new_nodeset << node
            while ( node.parent )
              node = node.parent
              new_nodeset << node unless new_nodeset.include? node
            end
          end
        end
        return new_nodeset

      when :predicate
        predicate = path_stack.shift
        new_nodeset = []
        Functions::size = nodeset.size
        nodeset.size.times do |index|
          node = nodeset[index]
          Functions::node = node
          Functions::index = index+1
          result = Predicate( predicate, node )
          if result.kind_of? Numeric
            new_nodeset << node if result == (index+1)
          elsif result.instance_of? Array
            new_nodeset << node if result.size > 0
          else
            new_nodeset << node if result
          end
        end
        return new_nodeset

      when :descendant_or_self
        rv = descendant_or_self( path_stack, nodeset )
        path_stack.clear
        return rv

      when :descendant
        results = []
        nt = nil
        for node in nodeset
          nt = node.node_type
          if nt == :element or nt == :document
            results += internal_parse(
              path_stack.clone.unshift( :descendant_or_self ),
              node.children )
          end
        end
        return results

      when :following_sibling
        results = []
        for node in nodeset
          all_siblings = node.parent.children
          current_index = all_siblings.index( node )
          following_siblings = all_siblings[ current_index+1 .. -1 ]
          results += internal_parse( path_stack.clone, following_siblings )
        end
        return results

      when :preceding_sibling
        results = []
        for node in nodeset
          all_siblings = node.parent.children
          current_index = all_siblings.index( node )
          preceding_siblings = all_siblings[ 0 .. current_index-1 ]
          results += internal_parse( path_stack.clone, preceding_siblings )
        end
        return results

      when :preceding
        new_nodeset = []
        for node in nodeset
          new_nodeset += preceding( node )
        end
        return new_nodeset

      when :following
        new_nodeset = []
        for node in nodeset
          new_nodeset += following( node )
        end
        return new_nodeset

      when :namespace
        new_set = []
        for node in nodeset
          if node.node_type == :element or node.node_type == :attribute
            new_nodeset << node.namespace
          end
        end
        return new_nodeset

      when :variable
        var_name = path_stack.shift
        return @variables[ var_name ]

      end
      nodeset
    end
  end
  
  class XPath # :nodoc:
    def self.liberal_match(element, path=nil, namespaces={},
        variables={}) # :nodoc:
			parser = LiberalXPathParser.new
			parser.namespaces = namespaces
			parser.variables = variables
			path = "*" unless path
			element = [element] unless element.kind_of? Array
			retried = false
			begin
  			parser.parse(path, element)
  		rescue NoMethodError => error
  		  retry if !retried
  		  raise error
  		end
    end

    def self.liberal_first(element, path=nil, namespaces={},
        variables={}) # :nodoc:
      parser = LiberalXPathParser.new
      parser.namespaces = namespaces
      parser.variables = variables
      path = "*" unless path
      element = [element] unless element.kind_of? Array
			retried = false
			begin
        parser.parse(path, element)[0]
  		rescue NoMethodError => error
  		  retry if !retried
  		  raise error
  		end
    end

    def self.liberal_each(element, path=nil, namespaces={},
        variables={}, &block) # :nodoc:
			parser = LiberalXPathParser.new
			parser.namespaces = namespaces
			parser.variables = variables
			path = "*" unless path
			element = [element] unless element.kind_of? Array
			retried = false
			begin
  			parser.parse(path, element).each( &block )
  		rescue NoMethodError => error
  		  retry if !retried
  		  raise error
  		end
    end
  end
  
  class Element # :nodoc:
    unless REXML::Element.public_instance_methods.include? :inner_xml
      def inner_xml # :nodoc:
        result = ""
        self.each_child do |child|
          if child.kind_of? REXML::Comment
            result << "<!--" + child.to_s + "-->"
          else
            result << child.to_s
          end
        end
        return result.strip
      end
    else
      warn("inner_xml method already exists.")
    end
    
    def base_uri # :nodoc:
      begin
        base_attribute = FeedTools::XmlHelper.try_xpaths(self, [
          '@xml:base'
        ])
        if parent == nil || parent.kind_of?(REXML::Document)
          return nil if base_attribute == nil
          return base_attribute.value
        end
        if base_attribute != nil && parent == nil
          return base_attribute.value
        elsif parent != nil && base_attribute == nil
          return parent.base_uri
        elsif parent != nil && base_attribute != nil
          parent_base_uri = parent.base_uri
          if parent_base_uri != nil
            uri = URI.parse(parent_base_uri)
            return (uri + base_attribute.value).to_s
          else
            return base_attribute.value
          end
        end
        return nil
      rescue
        return nil
      end
    end
  end
end

