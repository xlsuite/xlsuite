# :stopdoc:
class Regexp # :nodoc:
  def disable_capture
    re = ''
    self.source.scan(/\\.|[^\\\(]+|\(\?|\(/m) {|s|
      if s == '('
        re << '(?:'
      else
        re << s
      end
    }
    Regexp.new(re, self.options, self.kcode)
  end
end
# :startdoc:
