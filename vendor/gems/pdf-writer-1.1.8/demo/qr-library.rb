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
# $Id: qr-library.rb 104 2005-06-29 03:12:11Z austin $
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
  pdf.compressed    = true
  pdf.info.author   = "Ryan Davis"
  pdf.info.title    = "Ruby Library Quick Reference"
  pdf.info.subject  = "The Ruby Standard Library"

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

  title "Ruby Standard Library QuickRef"
  h1    "Class Hierarchy"
  pairs <<-'EOS'
Object	The parent object class. Includes <b>Kernel</b>.
  Array	Ordered integer-indexed collection of any object. Includes <b>Enumerable</b>.
  Hash	An unordered associative collection; keys may be any object. Includes <b>Enumerable</b>.
  String	Holds and manipulates an arbitrary sequence of bytes, typically representing characters. Includes <b>Comparable</b> and <b>Enumerable</b>.
  Symbol	Names in the ruby interpreter.
  IO	Base input/output class for Ruby. Includes <b>Enumerable</b>.
    File	An abstraction of a file object for IO purposes.
  File::Stat	Encapsulates File status information. Includes <b>Comparable</b>.
  Continuation	Holds a return address and execution context, allowing for nonlocal returns to the execution context.
  Exception	The root exception class. StandardError	The parent of exceptions that can be rescued without an exception specification. Children are: LocalJumpError, SystemStackError, ZeroDivisionError, RangeError (FloatDomainError), SecurityError, ThreadError, IOError (EOFError), ArgumentError, IndexError, RuntimeError, TypeError, SystemCallError (Errno::*), and RegexpError.
    SignalException	An exception raised from an OS signal.
    Interrupt	An interrupt exception.
    NoMemoryError	The interpreter is out of memory.
    ScriptError	Various script errors. Children are: LoadError, NameError, SyntaxError, and NotImplementedError.
    SystemExit	This exception is raised when Kernel#exit is called.
  Proc	Blocks of code bound to a set of local variables.
  Numeric	The base class that numbers are based on. Includes <b>Comparable</b>.
    Float	Real numbers using the native architecture’s double-precision floating point representation. Includes <b>Precision</b>
    Integer	The abstract class for the two whole number classes, Bignum and Fixnum. Includes <b>Precision</b>.
      Bignum	Holds large integers outside of Fixnum’s range. Autoconverts on overflow and underflow.
      Fixnum	Integer values that can fit in a native word (less one bit). Includes <b>Precision</b>.
  Regexp	Regular expression objects.
  Module	A collection of methods and constants that may be used as a namespace or mixed in to objects, other modules, or classes.
    Class	The base class for object classes.
  Thread	Encapsulates Ruby’s green threads.
  ThreadGroup	Allows the tracking of multiple threads as a group.
  Method	An instance of a method bound to a particular object. Calls are against that object.
    UnboundMethod	An method unassociated with an object, but can be bound against an object.
  Struct	A convenient way to bundle a number of attributes together, using accessor methods, without having to write an explicit class.
  Time	A class for encapsulating the concept of a moment in Time.
  Dir	Directory streams representing directories in the underlying file system.
  Binding	Encapsulate the execution context at some particular place in the code and retain this context for future use.
  Range	Represents an interval (a set of values with a start and an end).
  MatchData	A match for a regular expression. Returned by Regexp#match.
  TrueClass	The class of the global value <b>true</b>.
  FalseClass	The class of the global value <b>false</b>.
  NilClass	The class of the global value <b>nil</b>.
  EOS

  h1    "Modules"
  pairs <<-'EOS'
Comparable	Used by classes whose objects may be ordered. Requires the definition of the <b>&lt;=&gt;</b> operator for useful.
Enumerable	Provides collection classes with traversal, search, and sort methods. Must provide <b>each</b>; for some methods, contained objects must implement <b>&lt;=&gt;</b>.
Errno	Errno is created by the Ruby runtime to map operating system errors to Ruby classes. Each error will be a subclass of SystemCallError in the Errno namespace.
FileTest	Implements file test operations similar to those used in File::Stat. It exists as a standalone module, and its methods are also insinuated into the File class.
GC	Provides an interface to Ruby’s mark and sweep garbage collection mechanism.
Kernel	Implements a whole host of useful methods that don’t quite belong to any object.
Marshal	Converts Ruby objects into a byte stream, allowing them to be stored outside the currently active script. This data may subsequently be read and the original objects reconstituted.
Math	Contains module functions for basic trigonometric and transcendental functions.
ObjectSpace	Contains a number of routines that interact with the garbage collection facility and allow you to traverse all living objects with an iterator.
Precision	A mixin for concrete numeric classes with precision; the fineness of approximation of a real number.
Process	A collection of methods used to manipulate processes.
  EOS

  h1    "Standard Library"
  pairs <<-'EOS'
English	Include to allow for alternate, less-cryptic global variables names.
Env, importenv	Imports environment variables as global variables.
Win32API	Access to the Win32API directly.
abbrev	Provides Abbrev::abbrev, to calculate the set of unique abbreviations for a given set of strings.
base64	Provides conversion to and from base64 in the Base64 module. Top-level usage of base64 conversions is deprecated.
benchmark	Provides methods for benchmarking Ruby code.
bigdecimal	Large number arbitrary precision floating point support. Analagous to Bignum.
bigdecimal/jacobian	Computes Jacobian matrix of f at x.
bigdecimal/ludcmp	Provides LUSolve#ludecomp and #lusolve.
bigdecimal/math	Provides BigMath module.
bigdecimal/newton	Solves nonlinear algebraic equation system f = 0 by Newton’s method.
bigdecimal/nlsolve	Solving nonlinear algebraic equation system.
bigdecimal/util	BigDecimal utilities.
cgi-lib	CGI support library implemented as a delegator. Deprecated.
cgi	CGI support library.
cgi/session	Implements session support for CGI.
cgi/session/pstore	Implements session support for CGI using PStore.
complex	Implements the Complex class for complex numbers.
csv	CSV class for generating and parsing delimited data.
date	Provides Date and DateTime classes.
date/format	Provides date formatting utilities.
delegate	Delegation pattern; provides DelegateClass and SimpleDelegator.
dl	Dynamic definition of Ruby interfaces to dynamically loaded libraries. Also uses dl/import, dl/struct, dl/types, and dl/win32.
drb	“Distributed Ruby”. Has several other modules (drb/*).
e2mmap	Exception2MessageMapper module.
erb	Tiny “eRuby” embedded Ruby class.
eregex	Proof of concept extensions to regular expressions.
fileutils	Namespace for file utility methods: copying, moving, deleting, etc.
finalize	Finalizer wrapper methods.
find	Find module to for top-down traversal (and processing) of a set of file paths.
forwardable	Simple delegation of individual methods.
ftools	Extra tools for the file class. Deprecated, use fileutils.
generator	Convert an internal iterator to an external one.
getoptlong	Parses command-line options like the GNU getopt_long().
getopts	Obsolete option parser. getoptlong or optparse is preferred.
gserver	Implements a generic server.
digest	Cryptographic digest support: Digest::MD5 (digest/md5), Digest::RMD160 (digest/rmd160), Digest::SHA1 (digest/sha1), and Digest::SHA2 (digest/sha2) are all supported.
enumerator	Similar to Generator, creates an external enumerator from an enumerable method on an object.
etc	Provides access to user/group information. Called /etc because this information is traditionally in /etc/passwd on Unix.
fcntl	File control constants in the Fcntl namespace.
nkf	Network Kanji conversion filter.
racc	Ruby YACC. Only the runtime may be present in some installations.
rbconfig	Ruby compile-time configuration configuration constants.
sdbm	Ruby interface to SDBM.
socket	Socket support.
stringio	StringIO support; neither a String nor an IO, but a little of both.
strscan	Fast Ruby string scanner.
syck	Fast YAML parser.
tcltklib	Tcl/Tk support.
tktul	Tk utilities.
win32ole	Access to Win32’s OLE controls.
ipaddr	IPAddr class to manipulate IP addresses.
jcode	Helps handle Japanese (EUC/SJIS) strings.
kconv	Helps with Kanji conversion between JIS, SJIS, UTF-8, and UTF-16.
logger	Logger is a simple logging utility.
mailread	Reads a mail file and presents it as a class.
mathn	Extends Ruby with complex, rational, and matrix behaviour with additional behaviour.
matrix	Implements Matrix and Vector classes.
md5	Deprecated. Use digest/md5 instead.
mkmf	Used to create Makefile for extension modules. Use with <b>ruby -r mkmf extconf.rb</b>.
monitor	An extensible module to monitor an object for changes.
multi-tk	Support for multiple Tk interpreters.
mutex_m	Allows a random object to be treated as a Mutex.
net/ftp	FTP client library.
net/http	HTTP client library.
net/imap	IMAP client library.
net/pop	POP3 client library.
net/smtp	SMTP client library.
net/telnet	Telnet client library.
observer	An implementation of the Observer or Publish/Subscribe pattern.
open-uri	A wrapper for Kernel#open to allow http:// and ftp:// URIs as arguments.
open3	Spawns a program like popen, but with stderr.
optparse	Command-line option analysis. Preferred option parser in the standard library.
ostruct	OpenStruct, creates a Struct-like object with arbitrary attributes.
parsearg	Argument parser. Deprecated, uses getopts.
parsedate	Provides a parser for dates.
pathname	Represents a pathname to locate a file in a Unix filesystem. It does not represent the file, but the path name.
ping	A simple implementation of a ping-like utility using Ruby’s native socket support.
pp	Pretty printer for Ruby objects. Usable in place of #inspect.
prettyprint	Implementation of pretty printing algorithm.
profile	Ruby-based profiler. Use as <b>ruby -rprofile ...</b>.
profiler	The Ruby profiler implementation.
pstore	A filesystem “database” using Marshal formatting for storage.
rational	Implements rational numbers for Ruby (2 / 3 is 2 / 3, not 0.66 repeating).
readbytes	Adds IO#readbytes, reads fixed sized data and guarantees read data size.
remote-tk	Supports control of remote Tk interpreters.
resolv-replace	Replaces resolver behaviour on socket classes.
resolv	A resolver library written in Ruby.
rexml/document	Ruby Electric XML (REXML) parser.
rinda/rinda	A Ruby implementation of the Linda distributed computing paradigm. Uses drb.
rss/*	RSS 0.9 (rss/0.9), 1.0 (rss/1.0), or 2.0 (rss/2.0) interpreter.
rss/maker/*	RSS 0.9 (rss/maker/0.9), 1.0 (rss/maker/1.0), or 2.0 (rss/maker/2.0) maker.
rubyunit	Deprecated. Provides a wrapper for older RUnit classes to work as if they were Test::Unit classes.
scanf	scanf for Ruby.
set	An implementation of a Set calss for Ruby. A collection of unordered values with no duplicates.
sha1	Deprecated. Use digest/sha1 instead.
shell	Provides shell-like interaction. (?)
shellwords	Splits text into an array of tokens like Unix shells do.
singleton	A module to implement the Singleton pattern.
soap/soap	Native Ruby SOAP library. wsdl/* provides for service discovery.
sync	A two-phase lock with counter.
tcltk	Direct manipulation of Tcl/Tk utilities in a namespace.
tempfile	Manipulates temporary files (that will be deleted when the need for them goes away).
test/unit	Native unit testing library, Test::Unit.
thread	Thread support classes.
thwait	Thread synchronization classes.
time	Extensions to the Time class to support RFC2822 and RFC2616 formats, as well as others.
timeout	An execution timeout.
tk	An interface to Tk.
tkextlib/*	Support for various Tk extensions (ICONS, bwidtget, itcl, itk, etc.).
tmpdir	Retrieve the temporary directory path.
tracer	Tracing Ruby programs
tsort	Support for topological sorting.
un	Replacements for common Unix commands. <b>ruby -run -e cp -- ...</b>, etc.
uri	Libraries for interpreting uniform resource indicators (URIs).
weakref	A Weak reference class that is not garbage collected.
webrick	Webserver toolkit.
win32/registry	Access to the Win32 Regsitry.
win32/resolv	An interface to DNS and DHCP on Win32.
xmlrpc/*	Support for XML-RPC clients and servers.
xsd/*	XML instance parser.
yaml	YAML support.
  EOS

  h1    "ruby"
  h2    "Command-Line Options"
  pairs <<-'EOS'
-0[octal]	specify record separator (\0, if no argument).
-a	autosplit mode with -n or -p (splits $_ into $F).
-c	check syntax only.
-Cdirectory	cd to directory, before executing your script.
--copyright	print the copyright and exit.
-d	set debugging flags (set $DEBUG to true).
-e 'command'	one line of script. Several -e’s allowed.
-F regexp	split() pattern for autosplit (-a).
-h		prints summary of the options.
-i[extension]	edit ARGV files in place (make backup if extension supplied).
-Idirectory	specify $LOAD_PATH directory (may be used more than once).
-Kkcode	specifies KANJI (Japanese) code-set.
-l	enable line ending processing.
-n	assume ‘while gets(); ... end’ loop around your script.
-p	assume loop like -n but print line also like sed.
-rlibrary	require the library, before executing your script.
-s	enable some switch parsing for switches after script name.
-S	look for the script using PATH environment variable.
-T[level]	turn on tainting checks.
-v	print version number, then turn on verbose mode.
--version	print the version and exit.
-w	turn warnings on for your script.
-x[directory]	strip off text before #! line and perhaps cd to directory.
-X directory	causes Ruby to switch to the directory.
-y	turns on compiler debug mode.
  EOS

  h2    "Environment Variables"
  pairs <<-'EOS'
DLN_LIBRARY_PATH	Search path for dynamically loaded modules.
RUBYLIB	Additional search paths.
RUBYLIB_PREFIX	Add this prefix to each item in RUBYLIB. Windows only.
RUBYOPT	Additional command line options.
RUBYPATH	With -S, searches PATH, or this value for ruby programs.
RUBYSHELL	Shell to use when spawning.
  EOS

  h1    "irb"
  pre   "irb [options] [script [args]]"

  h2    "irb Command-Line Options"
  pairs <<-'EOS'
-f	Prevents the loading of ~/.irb.rc. Version 1.1 has a bug that swallows the next argument.
-m	Math mode. Overrides --inspect. Requires “mathn”.
-d	Sets $DEBUG to true. Same as “ruby -d ...”
-r module	Loads a module. Same as “ruby -r module ...”
--inspect	Turns on inspect mode. Default.
--noinspect	Turns off inspect mode.
--readline	Turns on readline support. Default.
--noreadline	Turns off readline support.
--prompt[-mode] prompt	Sets the prompt. ‘prompt’ must be one of ‘default’, ‘xmp’, ‘simple’, or ‘inf-ruby’.
--noprompt	Turns off the prompt.
--inf-ruby-mode	Turns on emacs support and turns off readline.
--sample-book-mode, --simple-prompt	Same as ‘--prompt simple’
--tracer	Turns on trace mode. Version 1.1 has a fatal bug with this flag.
--back-trace-limit	Sets the amount of backtrace to display in trace mode.
--context-mode	Sets the context mode (0-3) for multiple contexts. Defaults to 3. Not very clear how/why they differ.
--single-irb	Turns off multiple bindings (disables the irb command below), I think.
--irb_debug level	Sets internal debug level. For irb only.
-v, --version	Prints the version and exits.
  EOS

  h2    "irb commands"
  body  <<-'EOS'
irb accepts arbitrary Ruby commands and the special commands described
below.
  EOS
  pairs <<-'EOS'
irb_exit	Exits the current session, or the program if there are no other sessions.
fork block	forks and runs the given block.
irb_change_binding args	Changes to a secified binding.
source file	Loads a ruby file into the session.
irb [obj]	Starts a new session, with obj as self, if specified.
conf[.key[= val]]	Access the configuration of the session. May read and write single values.
jobs	Lists the known sessions.
fg (session#|thread-id|obj|self)	Switches to the specifed session.
kill session	Kills a specified session. Session may be specified the same as ‘fg’.
xmp eval-string	Evaluates the string and prints the string and result in a nice manner suitable for cut/paste operations. Only available with <b>require ‘irb/xmp’</b>.
  EOS

  h1    "Ruby Debugger"
  pre   "ruby -r debug ..."

  h2    "Commands"
  pairs <<-'EOS'
b[reak] [file:]line	Set breakpoint at given line in file (default current file).
b[reak] [file:]name	Set breakpoint at method in file.
b[reak]	Display breakpoints and watchpoints.
wat[ch] expr	Break when expression becomes true.
del[ete] [nnn]	Delete breakpoint nnn (default all).
disp[lay] expr	Display value of nnn every time debugger gets control.
disp[lay]	Show current displays.
undisp[lay] [nnn]	Remove display (default all).
c[ont]	Continue execution.
s[tep] nnn=1	Execute next nnn lines, stepping into methods.
n[ext] nnn=1	Execute next nnn lines, stepping over methods.
fi[nish]	Finish execution of the current function.
q[uit]	Exit the debugger.
w[here]	Display current stack frame.
f[rame]	Synonym for where.
l[ist] [start--end]	List source lines from start to end.
up nnn=1	Move up nnn levels in the stack frame.
down nnn=1	Move down nnn levels in the stack frame.
v[ar] g[lobal]	Display global variables.
v[ar] l[ocal]	Display local variables.
v[ar] i[nstance] obj	Display instance variables of obj.
v[ar] c[onst] Name	Display constants in class or module name.
m[ethod] i[nstance] obj	Display instance methods of obj.
m[ethod] Name	Display instance methods of the class or module name.
th[read] l[ist]	List all threads.
th[read] [c[ur[rent]]]	Display status of current thread.
th[read] [c[ur[rent]]] nnn	Make thread nnn current and stop it.
th[read] stop nnn	Make thread nnn current and stop it.
th[read] resume nnn	Resume thread nnn.
[p] expr	Evaluate expr in the current context. expr may include assignment to variables and method invocations.
empty	A null command repeats the last command.
  EOS

  x = pdf.absolute_right_margin + pdf.font_height(5)
  y = pdf.absolute_bottom_margin
  memo = %Q(Copyright © 2005 Ryan Davis with Austin Ziegler. PDF version by Austin Ziegler. Licensed under the  <c:alink uri="http://creativecommons.org/licenses/by-nc-sa/2.0/">Creative Commons Attribution-NonCommercial-ShareAlike</c:alink> Licence. The original HTML version is at <c:alink uri="http://www.zenspider.com/Languages/Ruby/QuickRef.html">Zen Spider</c:alink>. Generated by <c:alink uri="http://rubyforge.org/projects/ruby-pdf/">PDF::Writer</c:alink> #{PDF::Writer::VERSION} and PDF::QuickRef #{PDF::QuickRef::VERSION}.)
  pdf.add_text(x, y, memo, 5, 90)
  x = pdf.absolute_right_margin - 32
  y = pdf.absolute_bottom_margin + 24

  save_as "Ruby-Library-QuickRef.pdf"
end
