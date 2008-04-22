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

RAILS_DEFAULT_LOGGER = Logger.new("debug_odbc.log")
#Logger level default is the lowest available, Logger::DEBUG
#RAILS_DEFAULT_LOGGER.level = Logger::WARN
RAILS_DEFAULT_LOGGER.colorize_logging = false
ActiveRecord::Base.logger = RAILS_DEFAULT_LOGGER

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter  => "odbc",
    :dsn      => "a609_ora10_alice_test1",
    :username => "scott",
    :password => "tiger",
    :emulate_booleans => true,
    :trace    => false
  },
 'arunit2' => {
    :adapter  => "odbc",
    :dsn      => "a609_ora10_alice_test1",
    :username => "scott",
    :password => "tiger",
    :emulate_booleans => true,
    :trace    => false
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'

###########################################
# Using DSN-less connection

=begin
ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter  => "odbc",
    :conn_str => "Driver={OpenLink Lite for MySQL [6.0]};Database=rails_testdb1;Port=3306;UID=myuid;PWD=mypwd;"
    :emulate_booleans => true,
    :trace    => false
  },
 'arunit2' => {
    :adapter  => "odbc",
    :conn_str => "Driver={OpenLink Lite for MySQL [6.0]};Database=rails_testdb2;Port=3306;UID=myuid;PWD=mypwd;"
    :emulate_booleans => true,
    :trace    => false
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
=end

###########################################
# Using DB2

=begin
ActiveRecord::Base.configurations = {
  'arunit' => {
  :adapter  => "odbc",
  :dsn	    => "a610_db2_alice_rails1",
  :username => "db2admin",
  :password => "db2admin",
  :trace    => true,
  :convert_numeric_literals => true
  },
 'arunit2' => {
    :adapter  => "odbc",
    :dsn      => "a610_db2_alice_rails2",
    :username => "db2admin",
    :password => "db2admin",
    :trace    => true,
    :convert_numeric_literals => true
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
=end

###########################################
# Using Sybase 15

=begin
ActiveRecord::Base.configurations = {
  'arunit' => {
  :adapter  => "odbc",
  :dsn	    => "a609_syb15_trilby_testdb3",
  :username => "sa",
#  :password => "",
  :trace => true,
  :convert_numeric_literals => true
  },
 'arunit2' => {
  :adapter  => "odbc",
  :dsn	    => "a609_syb15_trilby_testdb4",
  :username => "sa",
#  :password => "",
  :trace => true,
  :convert_numeric_literals => true
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
=end

###########################################
puts "Using DSN: #{ActiveRecord::Base.configurations["arunit"][:dsn]}"
