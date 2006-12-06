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

require 'fileutils'

root_path = File.join(File.dirname(__FILE__), '../../..')
# Pathname claims only experimental support for non-Unix pathnames
unless RUBY_PLATFORM =~ /mswin32/
  require 'pathname'
  root_path = Pathname.new(root_path).cleanpath(true).to_s
end

t = Time.now
mod_stamp = "_#{t.year}_#{t.month}_#{t.day}"
f_env = File.expand_path(File.join(root_path,"config","environment.rb"))
f_env_backup = File.expand_path(File.join(root_path,"config",
             "environment.rb#{mod_stamp}"))

FileUtils.mv f_env,f_env_backup

File.open(f_env_backup,"r") {|f_in|
  File.open(f_env,"w") {|f_out|
    f_in.each_line do |ln|
      if ln =~ /^Rails::Initializer\.run/
        f_out.puts "# Added by OpenLink ODBC Data Adapter (odbc-rails) plugin"
        f_out.puts "Rails::Initializer.run(:load_plugins)"
        f_out.puts
      end
      f_out.puts ln
    end
  }
}
