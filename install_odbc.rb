#
#  $Id$
#
#  OpenLink ODBC Adapter for Ruby on Rails
#  Copyright (C) 2006 OpenLink Software
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject
#  to the following conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
#  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
#  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#
# Installation script for Rails ODBC Adapter
#
# * Locates an ActiveRecord installation.
#   - Looks for the latest version of any installed ActiveRecord gems.
#     (- Mac only: looking first under the Locomotive folder if installed)
#   - If no ActiveRecord gems are found, looks for a manually installed 
#     version of ActiveRecord in site_ruby.
# * Copies the essential ODBC adapter files into the ActiveRecord tree.
# * Makes a backup copy of active_record.rb and patches the original to 
#   include 'odbc' in the list of recognized Rails adapters.
# * Checks if Ruby ODBC Bridge is installed.

require 'rbconfig'
require 'find'
require 'ftools'
require 'fileutils'

include Config

puts "\n<< Installation script for Rails ODBC Adapter >>"

# Locate an ActiveRecord installation

if CONFIG['target_vendor'] =~ /apple/i
  puts "\nChecking if Locomotive is installed"
  lo = Dir.entries("/Applications").find_all { |l| l =~ /^locomotive/i }
  if !lo.empty?
    # Sort to ensure we use the latest Locomotive version
    $locomotiveDir = File.join("/Applications", lo.sort![-1])
    Find.find($locomotiveDir) { |p|
      $gemDir = p if File.basename(p) =~ /^gems$/i
    }
    if $gemDir
      ar = Dir.entries($gemDir).find_all { |g| g =~ /^activerecord/i }
      if !ar.empty?
        # Sort to ensure we install the ODBC adapter into the latest ActiveRecord
        # tree if multiple gem versions are installed.
        $activeRecDir = ar.sort![-1]
        $activeRecDir = File.join($gemDir, $activeRecDir, "lib", 
	    "active_record") unless $activeRecDir.nil?
      end
    end
  end
end

if !$activeRecDir
  puts "\nChecking if RubyGems is installed."
  begin
    require 'rubygems'
    $rubyGems = true
  rescue LoadError
  end

  if $rubyGems
    puts "Looking for installed ActiveRecord gems."
    ar = Dir.entries(File.join(Gem::dir,"gems")).find_all { |g| 
      g =~ /^activerecord-\d+\.\d+\.\d+$/i 
    }
    if !ar.empty?
      # Sort to ensure we install the ODBC adapter into the latest ActiveRecord
      # tree if multiple gem versions are installed.
      ar.sort!
      $activeRecDir = ar[-1]
      $activeRecDir = File.join(Gem::dir, "gems", $activeRecDir, "lib", 
	"active_record") unless $activeRecDir.nil?
    end
  end
end

if !$activeRecDir
  $sitedir = CONFIG["sitelibdir"]
  unless $sitedir
    version = CONFIG["MAJOR"] + "." + CONFIG["MINOR"]
    $libdir = File.join(CONFIG["libdir"], "ruby", version)
    $sitedir = $:.find { |x| x =~ /site_ruby/ }
    if !$sitedir
      $sitedir = File.join($libdir, "site_ruby")
    elsif $sitedir !~ Regexp.quote(version)
      $sitedir = File.join($sitedir, version)
    end
  end
  puts "An ActiveRecord gem could not be found."
  # ActiveRecord can be manually installed.
  # See install.rb in ActiveRecord distribution directory for details
  puts "\nLooking for ActiveRecord under #{$sitedir}"
  ar = File.join($sitedir,"active_record")
  $activeRecDir = ar if File.directory?(ar)
end

if $activeRecDir.nil?
  puts "\nAn ActiveRecord installation could not be found!" 
end

while true
  while $activeRecDir.nil?
    puts <<MSG1
Enter target directory or q to quit...
Please specify the location of your ActiveRecord tree by specifying the path
of the directory containing the connection_adapters and vendor directories.
(Windows users - Use / as the path separator, not \\)
MSG1
    i = gets.chomp.strip
    exit 1 if i =~/^q$/i
    if File.directory?(i) && 
       File.directory?(File.join(i, "connection_adapters"))
      $activeRecDir = i
      break
    else
      puts "ERROR>> [#{i}] is not a valid directory"
    end
  end
  puts "\nTarget ActiveRecord directory for install:\n[#{$activeRecDir}]"

  while true
    puts "Enter c to change target ActiveRecord directory, q to quit, " + 
         "i to install"
    i = gets.chomp.strip
    break if i =~ /^[ciq]/i
  end
  break if i =~ /^i/i
  exit 2 if i =~ /^q/i
  $activeRecDir=nil
end

puts "\nCopying ODBC Adapter files into the ActiveRecord tree."
puts "-"*60
Dir.chdir("lib/active_record")
Find.find(".") { |f|
  if f[-3..-1] == ".rb"
    dest = File.join($activeRecDir, *f.split(/\//))		
    # File::install fails if file already exists
    FileUtils.rm(dest, {:force => true})
    rc = File::install(f, dest, 0644, true)
    if rc != 1
      puts "ERROR>> File::install(#{f}, #{dest}, ...) failed"
      exit 3
    end
    puts
  end
}
puts "-"*60
puts 

puts "Checking RAILS_CONNECTION_ADAPTERS (active_record.rb) includes odbc."
Dir[File.join($activeRecDir, "..", "active_record.rb")].each do |path|
  Dir.chdir(File.dirname(path)) do |d|
    odbc_added = false
    t = Time.now
    mod_stamp = "_#{t.year}_#{t.month}_#{t.day}"
    tmpFileName = "tmp#{mod_stamp}"

    File.open(File.basename(path)) do |f|
      tmp = File.open(tmpFileName, "w+")
      f.each_line() do |line|
        if line =~ /\s*RAILS_CONNECTION_ADAPTERS\s*=\s*.*s*\(\s*(.*\S)(\s*\))/
          md1 = $1
          md2 = $2
          if md1 !~ /odbc/
	    odbc_added = true
            line.sub!(/\)/, md2[0,1] == " " ? "odbc )" : " odbc )")
	  end
        end
        tmp.puts(line)			
      end
      tmp.close
    end
	  
    if odbc_added
      puts "Copying active_record.rb to active_record.rb" + mod_stamp
      puts "Patching active_record.rb."
      FileUtils.mv("active_record.rb", "active_record.rb" + mod_stamp)
      FileUtils.mv(tmpFileName, "active_record.rb")
    else
      FileUtils.rm(tmpFileName)
    end
  end
end

# Check Ruby ODBC Bridge is installed

puts "\nChecking for Ruby ODBC Bridge." 

$odbcBridge = CONFIG['target_vendor'] =~ /apple/i ? "odbc.bundle" : "odbc.so"

if $locomotiveDir
  Find.find($locomotiveDir) { |p| 
    $odbcBridgeDir = File.dirname(p) if File.basename(p) =~ /^odbc.bundle/i
  }
  if $odbcBridgeDir.nil?
    puts <<MSG2
\nWARNING>> odbc.bundle* is not present under:\n\t#{$locomotiveDir}
\nThe Ruby ODBC Bridge must be installed before the Rails ODBC Adapter can be 
used.
MSG2
  else
    puts "\nodbc.bundle found in #{$odbcBridgeDir}"
  end
else
  $sitearchdir = CONFIG['sitearchdir']
  if File.exist?(File.join($sitearchdir, $odbcBridge))
    puts "#{$odbcBridge} found in #{$sitearchdir}"
  else
    puts <<MSG3
\nWARNING>> #{$odbcBridge} is not present in:\n\t#{$sitearchdir}
\nThe Ruby ODBC Bridge must be installed before the Rails ODBC Adapter can be 
used.
MSG3
  end
end
puts "\nDone."
