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

print "Using native ODBC\n"
require_dependency 'fixtures/course'
require 'logger'

#ActiveRecord::Base.logger = Logger.new(STDOUT)
#ActiveRecord::Base.logger = Logger.new("debug_odbc.log")
#Logger level default is the lowest available, Logger::DEBUG
#ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.establish_connection(
  :adapter  => "odbc",
  :dsn	    => "a604-ora10-alice-testdb1",
  :username => "oracle",
  :password => "oracle",
  :trace => true
)

Course.establish_connection(
  :adapter  => "odbc",
  :dsn	    => "a604-ora10-alice-testdb2",
  :username => "oracle",
  :password => "oracle",
  :trace => true
)

###########################################
# Using Sybase

=begin
ActiveRecord::Base.establish_connection(
  :adapter  => "odbc",
  :dsn	    => "a609_syb15_trilby_testdb3",
  :username => "sa",
  :trace => true,
  :convert_numeric_literals => true
)

Course.establish_connection(
  :adapter  => "odbc",
  :dsn	    => "a609_syb15_trilby_testdb4",
  :username => "sa",
  :trace => true,
  :convert_numeric_literals => true
)
=end

###########################################
# Using DB2

=begin
ActiveRecord::Base.establish_connection(
  :adapter  => "odbc",
  :dsn	    => "a609_db2_alice_rails1",
  :username => "db2admin",
  :password => "db2admin",
  :trace => true,
  :convert_numeric_literals => true
)

Course.establish_connection(
  :adapter  => "odbc",
  :dsn	    => "a609_db2_alice_rails2",
  :username => "db2admin",
  :password => "db2admin",
  :trace => true,
  :convert_numeric_literals => true
)
=end
