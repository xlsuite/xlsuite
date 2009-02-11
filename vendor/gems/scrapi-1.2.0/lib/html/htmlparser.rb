module HTML #:nodoc:

    # A parser for SGML, using the derived class as static DTD.
    
    class SGMLParser
    
    # Regular expressions used for parsing:
    Interesting = /[&<]/
    Incomplete = Regexp.compile('&([a-zA-Z][a-zA-Z0-9]*|#[0-9]*)?|' +
                                '<([a-zA-Z][^<>]*|/([a-zA-Z][^<>]*)?|' +
                                '![^<>]*)?')
    
    Entityref = /&([a-zA-Z][-.a-zA-Z0-9]*)[^-.a-zA-Z0-9]/
    Charref = /&#([0-9]+)[^0-9]/
    
    Starttagopen = /<[>a-zA-Z]/
    Endtagopen = /<\/[<>a-zA-Z]/
    # Assaf: fixed to allow tag to close itself (XHTML)
    Endbracket = /<|>|\/>/
    Special = /<![^<>]*>/
    Commentopen = /<!--/
    Commentclose = /--[ \t\n]*>/
    Tagfind = /[a-zA-Z][a-zA-Z0-9.-]*/
    # Assaf: / is no longer part of allowed attribute value
    Attrfind = Regexp.compile('[\s,]*([a-zA-Z_][a-zA-Z_0-9.-]*)' +
                                '(\s*=\s*' +
                                "('[^']*'" +
                                '|"[^"]*"' +
                                '|[-~a-zA-Z0-9,.:+*%?!()_#=]*))?')
    
    Entitydefs =
        {'lt'=>'<', 'gt'=>'>', 'amp'=>'&', 'quot'=>'"', 'apos'=>'\''}
    
    def initialize(verbose=false)
        @verbose = verbose
        reset
    end
    
    def reset
        @rawdata = ''
        @stack = []
        @lasttag = '???'
        @nomoretags = false
        @literal = false
    end
    
    def has_context(gi)
        @stack.include? gi
    end
    
    def setnomoretags
        @nomoretags = true
        @literal = true
    end
    
    def setliteral(*args)
        @literal = true
    end
    
    def feed(data)
        @rawdata << data
        goahead(false)
    end
    
    def close
        goahead(true)
    end
    
    def goahead(_end)
        rawdata = @rawdata
        i = 0
        n = rawdata.length
        while i < n
        if @nomoretags
            handle_data(rawdata[i..(n-1)])
            i = n
            break
        end
        j = rawdata.index(Interesting, i)
        j = n unless j
        if i < j
            handle_data(rawdata[i..(j-1)])
        end
        i = j
        break if (i == n)
        if rawdata[i] == ?< #
            if rawdata.index(Starttagopen, i) == i
            if @literal
                handle_data(rawdata[i, 1])
                i += 1
                next
            end
            k = parse_starttag(i)
            break unless k
            i = k
            next
            end
            if rawdata.index(Endtagopen, i) == i
            k = parse_endtag(i)
            break unless k
            i = k
            @literal = false
            next
            end
            if rawdata.index(Commentopen, i) == i
            if @literal
                handle_data(rawdata[i,1])
                i += 1
                next
            end
            k = parse_comment(i)
            break unless k
            i += k
            next
            end
            if rawdata.index(Special, i) == i
            if @literal
                handle_data(rawdata[i, 1])
                i += 1
                next
            end
            k = parse_special(i)
            break unless k
            i += k
            next
            end
        elsif rawdata[i] == ?& #
            if rawdata.index(Charref, i) == i
            i += $&.length
            handle_charref($1)
            i -= 1 unless rawdata[i-1] == ?;
            next
            end
            if rawdata.index(Entityref, i) == i
            i += $&.length
            handle_entityref($1)
            i -= 1 unless rawdata[i-1] == ?;
            next
            end
        else
            raise RuntimeError, 'neither < nor & ??'
        end
        # We get here only if incomplete matches but
        # nothing else
        match = rawdata.index(Incomplete, i)
        unless match == i
            handle_data(rawdata[i, 1])
            i += 1
            next
        end
        j = match + $&.length
        break if j == n # Really incomplete
        handle_data(rawdata[i..(j-1)])
        i = j
        end
        # end while
        if _end and i < n
        handle_data(@rawdata[i..(n-1)])
        i = n
        end
        @rawdata = rawdata[i..-1]
    end
    
    def parse_comment(i)
        rawdata = @rawdata
        if rawdata[i, 4] != '<!--'
        raise RuntimeError, 'unexpected call to handle_comment'
        end
        match = rawdata.index(Commentclose, i)
        return nil unless match
        matched_length = $&.length
        j = match
        handle_comment(rawdata[i+4..(j-1)])
        j = match + matched_length
        return j-i
    end
    
    def parse_starttag(i)
        rawdata = @rawdata
        j = rawdata.index(Endbracket, i + 1)
        return nil unless j
        attrs = []
        if rawdata[i+1] == ?> #
        # SGML shorthand: <> == <last open tag seen>
        k = j
        tag = @lasttag
        else
        match = rawdata.index(Tagfind, i + 1)
        unless match
            raise RuntimeError, 'unexpected call to parse_starttag'
        end
        k = i + 1 + ($&.length)
        tag = $&.downcase
        @lasttag = tag
        end
        while k < j
        # Assaf: fixed to allow tag to close itself (XHTML)
        break unless idx = rawdata.index(Attrfind, k) and idx < j
        matched_length = $&.length
        attrname, rest, attrvalue = $1, $2, $3
        if not rest
            attrvalue = '' # was: = attrname
        # Assaf: fixed to handle double quoted attribute values properly
        elsif (attrvalue[0] == ?' && attrvalue[-1] == ?') or
            (attrvalue[0] == ?" && attrvalue[-1] == ?")
            attrvalue = attrvalue[1..-2]
        end
        attrs << [attrname.downcase, attrvalue]
        k += matched_length
        end
        # Assaf: fixed to allow tag to close itself (XHTML)
        if rawdata[j,2] == '/>'
        j += 2
        finish_starttag(tag, attrs)
        finish_endtag(tag)
        else
        if rawdata[j] == ?> #
            j += 1
        end
        finish_starttag(tag, attrs)
        end
        return j
    end
    
    def parse_endtag(i)
        rawdata = @rawdata
        j = rawdata.index(Endbracket, i + 1)
        return nil unless j
        tag = (rawdata[i+2..j-1].strip).downcase
        if rawdata[j] == ?> #
        j += 1
        end
        finish_endtag(tag)
        return j
    end
    
    def finish_starttag(tag, attrs)
        method = 'start_' + tag
        if self.respond_to?(method)
        @stack << tag
        handle_starttag(tag, method, attrs)
        return 1
        else
        method = 'do_' + tag
        if self.respond_to?(method)
            handle_starttag(tag, method, attrs)
            return 0
        else
            unknown_starttag(tag, attrs)
            return -1
        end
        end
    end
    
    def finish_endtag(tag)
        if tag == ''
        found = @stack.length - 1
        if found < 0
            unknown_endtag(tag)
            return
        end
        else
        unless @stack.include? tag
            method = 'end_' + tag
            unless self.respond_to?(method)
            unknown_endtag(tag)
            end
            return
        end
        found = @stack.index(tag) #or @stack.length
        end
        while @stack.length > found
        tag = @stack[-1]
        method = 'end_' + tag
        if respond_to?(method)
            handle_endtag(tag, method)
        else
            unknown_endtag(tag)
        end
        @stack.pop
        end
    end
    
    def parse_special(i)
        rawdata = @rawdata
        match = rawdata.index(Endbracket, i+1)
        return nil unless match
        matched_length = $&.length
        handle_special(rawdata[i+1..(match-1)])
        return match - i + matched_length
    end
    
    def handle_starttag(tag, method, attrs)
        self.send(method, attrs)
    end
    
    def handle_endtag(tag, method)
        self.send(method)
    end
    
    def report_unbalanced(tag)
        if @verbose
        print '*** Unbalanced </' + tag + '>', "\n"
        print '*** Stack:', self.stack, "\n"
        end
    end
    
    def handle_charref(name)
        n = Integer(name) rescue -1
        if !(0 <= n && n <= 255)
        unknown_charref(name)
        return
        end
        handle_data(n.chr)
    end
    
    def handle_entityref(name)
        table = Entitydefs
        if table.include?(name)
        handle_data(table[name])
        else
        unknown_entityref(name)
        return
        end
    end
    
    def handle_data(data)
    end
    
    def handle_comment(data)
    end
    
    def handle_special(data)
    end
    
    def unknown_starttag(tag, attrs)
    end
    def unknown_endtag(tag)
    end
    def unknown_charref(ref)
    end
    def unknown_entityref(ref)
    end
    
    end


    # (X)HTML parser.
    #
    # Parses a String and returns an REXML::Document with the (X)HTML content.
    #
    # For example:
    #   html = "<p>paragraph</p>"
    #   parser = HTMLParser.new(html)
    #   puts parser.document
    #
    # Requires a patched version of SGMLParser.
    class HTMLParser < SGMLParser
    
        attr :document

        def self.parse(html)
            parser = HTMLParser.new
            parser.feed(html)
            parser.document
        end
    
        def initialize()
            super
            @document = HTML::Document.new("")
            @current = @document.root
        end
    
        def handle_data(data)
            @current.children << HTML::Text.new(@current, 0, 0, data)
        end
    
        def handle_comment(data)
        end
    
        def handle_special(data)
        end
    
        def unknown_starttag(tag, attrs)
            attrs = attrs.inject({}) do |hash, attr|
                hash[attr[0].downcase] = attr[1]
                hash
            end
            element = HTML::Tag.new(@current || @document, 0, 0, tag.downcase, attrs, true)
            @current.children << element
            @current = element
        end
        
        def unknown_endtag(tag)
            @current = @current.parent if @current.parent
        end
        
        def unknown_charref(ref)
        end
        
        def unknown_entityref(ref)
            @current.children << HTML::Text.new(@current, 0, 0, "&amp;#{ref}&lt;")
        end
    
    end

end