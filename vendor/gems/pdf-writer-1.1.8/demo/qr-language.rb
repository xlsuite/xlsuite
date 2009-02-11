#--
# PDF::Writer for Ruby.
#   http://rubyforge.org/projects/ruby-pdf/
#   Copyright 2003 - 2005 Austin Ziegler.
#
#   This Quick Reference card program is copyright 2003–2005 Ryan
#   Davis and is licensed under the Creative Commons Attribution
#   NonCommercial
#   ShareAlike[http://creativecommons.org/licenses/by-nc-sa/2.0/] licence.
#
#   See LICENCE in the main distribution for full licensing information.
#
# $Id: qr-language.rb 156 2007-09-06 17:40:27Z austin $
#++
begin
  require 'pdf/writer'
rescue LoadError => le
  if le.message =~ %r{pdf/writer$}
    $LOAD_PATH.unshift("../lib")
    require 'pdf/writer'
  else
    raise
  end
end

require 'pdf/quickref'

if ARGV[0].nil?
  paper = "LETTER"
else
  if PDF::Writer::PAGE_SIZES.has_key?(ARGV[0])
    paper = ARGV[0]
  else
    puts <<-EOS
usage: #{File.basename($0)} [paper-size]

  paper-size must be one of the standard PDF::Writer page sizes.
  Default paper-size is LETTER.
    EOS
    exit 0
  end
end

PDF::QuickRef.make(paper, 3) do
# pdf.compressed    = true
  pdf.info.author   = "Ryan Davis"
  pdf.info.title    = "Ruby Language Quick Reference"
  pdf.info.subject  = "The Ruby Programming Language"

  self.title_font_size = 13
  self.h1_font_size    = 10
  self.h2_font_size    = 8
  self.h3_font_size    = 7
  self.h4_font_size    = 6
  self.body_font_size  = 5

  enc = {
    :encoding     => 'WinAnsiEncoding',
    :differences  => {
      148 => "copyright",
    }
  }
  self.title_font_encoding  = enc
  self.heading_font_encoding  = enc
  self.body_font_encoding  = enc
  self.code_font_encoding  = enc

  title "Ruby Language QuickRef"
  h1    "General Syntax Rules"
  lines <<-'EOS'
Comments start with a pound/sharp (#) character and go to EOL.
Lines between ‘=begin’ and ‘=end’ are skipped by the interpreter.
Ruby programs are sequence of expressions.
Each expression is delimited by semicolons (;) or newlines unless obviously incomplete (e.g. trailing ‘+’).
Backslashes at the end of line does not terminate expression.
  EOS

  h1     "Reserved Words"
  codelines <<-'EOS'
alias   and     BEGIN   begin   break   case
class   def     defined do      else    elsif
END     end     ensure  false   for     if
in      module  next    nil     not     or
redo    rescue  retry   return  self    super
then    true    undef   unless  until   when 
while   yield
  EOS

  h1     "Types"
  body   <<-'EOS'
Basic types are numbers, strings, ranges, regexen, symbols, arrays, and
hashes. Also included are files because they are used so often.
  EOS

  h2     "Numbers"
  lines  <<-'EOS'
123 1_234 123.45 1.2e-3
0xffff (hex) 0b01011 (binary) 0377 (octal)
?a       ASCII character
?\C-a    Control-a
?\M-a    Meta-a
?\M-\C-a Meta-Control-a
  EOS

  h2      "Strings"
  body    <<-'EOS'
In all of the %() cases below, you may use any matching characters or any
single character for delimiters. %[], %!!, %@@, etc.
  EOS
  codelines <<-'EOS'
'no interpolation'
"#{interpolation} and backslashes\n"
%q(no interpolation)
%Q(interpolation and backslashes)
%(interpolation and backslashes)
`echo command interpretation with interpolation and backslashes`
%x(echo command interpretation with interpolation and backslashes)
  EOS

  h3      "Backslashes"
  pre     <<-'EOS'
    \t (tab), \n (newline), \r (carriage return),
    \f (form feed), \b (backspace), \a (bell),
    \e (escape), \s (whitespace), \nnn (octal),
    \xnn (hexadecimal), \cx (control x),
    \C-x (control x), \M-x (meta x),
    \M-\C-x (meta control x)
  EOS

  h3      "Here Docs"
  pre     <<-'EOS'
    &lt;&lt;identifier    # interpolation
    &lt;&lt;"identifier"  # interpolation
    &lt;&lt;'identifier'  # no interpolation
    &lt;&lt;-identifier   # interpolation, indented end
    &lt;&lt;-"identifier" # interpolation, indented end
    &lt;&lt;-'identifier' # no interpolation, indented end
  EOS

  h2      "Symbols"
  body    <<-'EOS'
A symbol (:symbol) is an immutable name used for identifiers,
variables, and operators.
  EOS

  h2      "Ranges"
  pre     <<-'EOS'
    1..10
    'a'..'z'
    (1..10) === 5   -&gt; true
    (1..10) === 15  -&gt; false

    # prints lines starting at 'start' and
    # ending at 'end'
  while gets
    print if /start/../end/
  end

  class RangeThingy
    def &lt;=&gt;(rhs)
      # ...
    end
    def succ
      # ...
    end
  end
  range = RangeThingy.new(lower_bound) .. RangeThingy.new(upper_bound)
  EOS

  h2      "Regular Expressions"
  pre     <<-'EOS'
    /normal regex/[xim]
    %r|alternate form|[xim]
    Regexp.new(pattern, options)
  EOS
  pairs   <<-'EOS'
.	any character except newline
[set]	any single character of set
[^set]	any single character NOT of set
*	0 or more previous regular expression
*?	0 or more previous regular expression (non greedy)
+	1 or more previous regular expression
+?	1 or more previous regular expression (non greedy)
?	0 or 1 previous regular expression
|	alternation
( )	grouping regular expressions
^	beginning of a line or string
$	end of a line or string
#{m,n}	at least m but most n previous regular expression
#{m,n}?	at least m but most n previous regular expression (non greedy)
\A	beginning of a string
\b	backspace (0x08, inside [] only)
\B	non-word boundary
\b	word boundary (outside [] only)
\d	digit, same as[0-9]
\D	non-digit
\S	non-whitespace character
\s	whitespace character[ \t\n\r\f]
\W	non-word character
\w	word character[0-9A-Za-z_]
\z	end of a string
\Z	end of a string, or before newline at the end
(?# )	comment
(?: )	grouping without backreferences
(?= )	zero-width positive look-ahead assertion (?! )	zero-width negative look-ahead assertion
(?ix-ix)	turns on/off i/x options, localized in group if any.
(?ix-ix: )	turns on/off i/x options, localized in non-capturing group.
  EOS

  h2      "Arrays"
  pre     <<-'EOS'
  [1, 2, 3]
  %w(foo bar baz)     # no interpolation
  %W(foo #{bar} baz)  # interpolation
  EOS
  body    <<-'EOS'
Indexes may be negative, and they index backwards (-1 is the last element).
  EOS

  h2      "Hashes"
  pre     <<-'EOS'
  { 1 =&gt; 2, 2 =&gt; 4, 3 =&gt; 6 }
  { expr =&gt; expr, ... }
  EOS

  h2      "Files"
  body    "Common methods include:"
  lines   <<-'EOS'
File.join(p1, p2, ... pN) =&gt; “p1/p2/.../pN” platform independent paths
File.new(path, mode_string="r") =&gt; file
File.new(path, mode_num [, perm_num]) =&gt; file
File.open(filename, mode_string="r") {|file| block} -&gt; nil
File.open(filename [, mode_num [, perm_num ]]) {|file| block} -&gt; nil
IO.foreach(path, sepstring=$/) {|line| block}
IO.readlines(path) =&gt; array
  EOS

  h3      "Mode Strings"
  pairs   <<-'EOS'
r	Read-only, starts at beginning of file (default mode).
r+	Read-write, starts at beginning of file.
w	Write-only, truncates existing file to zero length or creates a new file for writing.
w+	Read-write, truncates existing file to zero length or creates a new file for reading and writing.
a	Write-only, starts at end of file if file exists, otherwise creates a new file for writing.
a+	Read-write, starts at end of file if file exists, otherwise creates a new file for reading and writing.
b	Binary file mode (may appear with any of the key letters listed above). Only <b>necessary</b> for DOS/Windows.
  EOS

  h1      "Variables and Constants"
  pre     <<-'EOS'
  $global_variable
  @instance_variable
  [OtherClass::]CONSTANT
  local_variable
  EOS

  h1      "Pseudo-variables"
  pairs   <<-'EOS'
self	the receiver of the current method
nil	the sole instance of NilClass (represents false)
true	the sole instance of TrueClass (typical true value)
false	the sole instance of FalseClass (represents false)
__FILE__	the current source file name.
__LINE__	the current line number in the source file.
  EOS

  h1      "Pre-defined Variables"
  pairs   <<-'EOS'
$!	The exception information message set by ‘raise’.
$@	Array of backtrace of the last exception thrown.
$&amp;	The string matched by the last successful pattern match in this scope.
$`	The string to the left  of the last successful match.
$'	The string to the right of the last successful match.
$+	The last bracket matched by the last successful match.
$1	The Nth group of the last successful match. May be &gt; 1.
$~	The information about the last match in the current scope.
$=	The flag for case insensitive, nil by default.
$/	The input record separator, newline by default.
$\	The output record separator for the print and IO#write. Default is nil.
$,	The output field separator for the print and Array#join.
$;	The default separator for String#split.
$.	The current input line number of the last file that was read.
$&lt;	The virtual concatenation file of the files given on command line.
$&gt;	The default output for print, printf. $stdout by default.
$_	The last input line of string by gets or readline.
$0	Contains the name of the script being executed. May be assignable.
$*	Command line arguments given for the script sans args.
$$	The process number of the Ruby running this script.
$?	The status of the last executed child process.
$:	Load path for scripts and binary modules by load or require.
$"	The array contains the module names loaded by require.
$DEBUG	The status of the -d switch.
$FILENAME	Current input file from $&lt;. Same as $&lt;.filename.
$LOAD_PATH	The alias to the $:.
$stderr	The current standard error output.
$stdin	The current standard input.
$stdout	The current standard output.
$VERBOSE	The verbose flag, which is set by the -v switch.
$-0	The alias to $/.
$-a	True if option -a is set. Read-only variable.
$-d	The alias to $DEBUG.
$-F	The alias to $;.
$-i	In in-place-edit mode, this variable holds the extention, otherwise nil.
$-I	The alias to $:.
$-l	True if option -l is set. Read-only variable.
$-p	True if option -p is set. Read-only variable.
$-v	The alias to $VERBOSE.
  EOS

  h1      "Pre-defined Global Constants"
  pairs   <<-'EOS'
TRUE	The typical true value.
FALSE	The false itself.
NIL	The nil itself.
STDIN	The standard input. The default value for $stdin.
STDOUT	The standard output. The default value for $stdout.
STDERR	The standard error output. The default value for $stderr.
ENV	The hash contains current environment variables.
ARGF	The alias to the $&lt;.
ARGV	The alias to the $*.
DATA	The file object of the script, pointing just after __END__.
RUBY_VERSION	The ruby version string (VERSION was depricated).
RUBY_RELEASE_DATE	The relase date string.
RUBY_PLATFORM	The platform identifier.
  EOS

  h1      "Expressions"
  h2      "Terms"
  body    <<-'EOS'
Terms are expressions that may be a basic type (listed above), a shell
command, variable reference, constant reference, or method invocation.
  EOS

  h2      "Operators and Precedence"
  codelines <<-'EOS'
::
[]
**
- (unary) + (unary) ! ~
*  /  %
+  -
&lt;&lt;  &gt;&gt;
&amp;
|  ^
&gt;  &gt;=  &lt;  &lt;=
&lt;=&gt; == === != =~ !~
&amp;&amp;
||
.. ...
= (+=, -=, ...)
not
and or
  EOS

  h2      "Control Expressions"
  pre     <<-'EOS'
if bool-expr [then]
  body
elsif bool-expr [then]
  body
else
  body
end

unless bool-expr [then]
  body
else
  body
end

expr if     bool-expr
expr unless bool-expr

case target-expr
    # (comparisons may be regexen)
  when comparison [, comparison]... [then]
    body
  when comparison [, comparison]... [then]
    body
  ...
[else
  body]
end

while bool-expr [do]
 body
end

until bool-expr [do]
 body
end

begin
 body
end while bool-expr

begin
 body
end until bool-expr

for name[, name]... in expr [do]
  body
end

expr.each do | name[, name]... |
  body
end

expr while bool-expr
expr until bool-expr
  EOS
  pairs   <<-'EOS'
break	terminates loop immediately.
redo	immediately repeats w/o rerunning the condition.
next	starts the next iteration through the loop.
retry	restarts the loop, rerunning the condition.
  EOS

  h1      "Invoking a Method"
  body    <<-'EOS'
Nearly everything available in a method invocation is optional, consequently
the syntax is very difficult to follow. Here are some examples:
  EOS
  lines   <<-'EOS'
method
obj.method
Class::method
method(arg1, arg2)
method(arg1, key1 =&gt; val1, key2 =&gt; val2, aval1, aval2) { block }
method(arg1, *[arg2, arg3]) becomes: method(arg1, arg2, arg3)
  EOS
  pre     <<-'EOS'
call   := [receiver ('::' | '.')] name [params] [block]
params := ( [param]* [, hash] [*arr] [&amp;proc] )
block  := { body } | do body end
  EOS

  h1      "Defining a Class"
  body    "Class names begin with capital characters."
  pre     <<-'EOS'
class Identifier [ &lt; Superclass ]; ... ; end

    # Singleton classes, or idioclasses;
    # add methods to a single instance
    # obj can be self
class &lt;&lt; obj; ...; end
  EOS

  h1      "Defining a Module"
  body    "Module names begin with capital characters."
  pre     "module Identifier; ...; end"

  h1      "Defining a Method"
  pre     <<-'EOS'
def method_name(arg_list); ...; end
def expr.method_name(arg_list); ...; end
  EOS
  lines   <<-'EOS'
arg_list := ['('] [varname*] ['*' listname] ['&' blockname] [')']
Arguments may have default values (varname = expr).
Method definitions may not be nested.
method_name may be an operator: &lt;=&gt;, ==, ===, =~, &lt;, &lt;=, &gt; &gt;=, +, -, *, /, %, **, &lt;&lt;, &gt;&gt;, ~, +@, -@, [], []= (the last takes two arguments)
  EOS

  h2      "Access Restriction"
  pairs   <<-'EOS'
public	totally accessable.
protected	accessable only by instances of class and direct descendants. Even through hasA relationships. (see below)
private	accessable only by instances of class.
  EOS
  body    <<-'EOS'
Restriction used without arguments set the default access control. Used with
arguments, sets the access of the named methods and constants.
  EOS
  pre     <<-'EOS'
class A
  protected
  def protected_method; ...; end
end
class B &lt; A
  public
  def test_protected
    myA = A.new
    myA.protected_method
  end
end
b = B.new.test_protected
  EOS

  h3      "Accessors"
  body    "Module provides the following utility methods:"
  pairs   <<-'EOS'
attr_reader &lt;attribute&gt;[, &lt;attribute&gt;]...	Creates a read-only accessor for each &lt;attribute&gt;.
attr_writer &lt;attribute&gt;[, &lt;attribute&gt;]...	Creates a write-only accessor for each &lt;attribute&gt;.
attr &lt;attribute&gt; [, &lt;writable&gt;]	Equivalent to "attr_reader &lt;attribute&gt;; attr_writer &lt;attribute&gt; if &lt;writable&gt;"
attr_accessor &lt;attribute&gt;[, &lt;attribute&gt;]...	Equivalent to "attr &lt;attribute&gt;, true" for each argument.
  EOS

  h2      "Aliasing"
  pre     "alias &lt;old&gt; &lt;new&gt;"
  body    <<-'EOS'
Creates a new reference to whatever old referred to. old can be any existing
method, operator, global. It may not be a local, instance, constant, or
class variable.
  EOS

  h1      "Blocks, Closures, and Procs"
  h2      "Blocks/Closures"
  body    "Blocks must follow a method invocation:"
  pre     <<-'EOS'
invocation do ... end
invocation do || ... end
invocation do |arg_list| ... end
invocation { ... }
invocation { || ... }
invocation { |arg_list| ... }
  EOS
  lines   <<-'EOS'
Blocks are full closures, remembering their variable context.
Blocks are invoked via yield and may be passed arguments.
Block arguments may not have default parameters.
Brace form ({/}) has higher precedence and will bind to the last parameter if the invocation is made without parentheses.
do/end form has lower precedence and will bind to the invocation even without parentheses.
  EOS

  h2      "Proc Objects"
  body    "See class Proc for more information. Created via:"
  pre     <<-'EOS'
Kernel#proc (or Kernel#lambda)
Proc#new
&amp;block argument on a method
  EOS

  h2      "Exceptions"
  pre     <<-'EOS'
begin
  expr
[ rescue [ exception_class [ =&gt; var ], ... ]
  expr ]
[ else
  expr ]
[ ensure
  expr ]
end

raise [ exception_class, ] [ message ]
  EOS
  body    <<-'EOS'
The default exception_class for rescue is StandardError, not Exception.
Raise without an exception_class raises a RuntimeError. All exception
classes must inherit from Exception or one of its children (listed below).
EOS
  pairs   <<-'EOS'
StandardError	LocalJumpError, SystemStackError, ZeroDivisionError, RangeError (FloatDomainError), SecurityError, ThreadError, IOError (EOFError), ArgumentError, IndexError, RuntimeError, TypeError, SystemCallError (Errno::*), RegexpError
SignalException
Interrupt
NoMemoryError
ScriptError	LoadError, NameError, SyntaxError, NotImplementedError
SystemExit
  EOS

  h2      "Catch and Throw"
  pre     <<-'EOS'
catch :label do
  expr
  throw :label
end
  EOS

  hline

  x = pdf.absolute_right_margin + pdf.font_height(5)
  y = pdf.absolute_bottom_margin
  memo = %Q(Copyright © 2005 Ryan Davis with Austin Ziegler. PDF version by Austin Ziegler. Licensed under the  <c:alink uri="http://creativecommons.org/licenses/by-nc-sa/2.0/">Creative Commons Attribution-NonCommercial-ShareAlike</c:alink> Licence. The original HTML version is at <c:alink uri="http://www.zenspider.com/Languages/Ruby/QuickRef.html">Zen Spider</c:alink>. Generated by <c:alink uri="http://rubyforge.org/projects/ruby-pdf/">PDF::Writer</c:alink> #{PDF::Writer::VERSION} and PDF::QuickRef #{PDF::QuickRef::VERSION}.)
  pdf.add_text(x, y, memo, 5, 90)
  x = pdf.absolute_right_margin - 32
  y = pdf.absolute_bottom_margin + 24

  save_as "Ruby-Language-QuickRef.pdf"
end
