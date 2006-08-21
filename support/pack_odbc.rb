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
# Copies Rails ODBC adapter files from development ActiveRecord tree to a
# staging area ready for packaging.
#

require 'fileutils'
require 'find'
require 'ftools'
require 'rdoc/rdoc'

# Development ActiveRecord source tree
$AR_DEV_ROOT = "/data/radrails/carl/activerecord_svn_co"
# Staging area
$PACK_ROOT = "/tmp/rails_odbc_pack"
# Location of miscellaneous files not in $AR_DEV_ROOT
$MISC_ROOT = "/dev/rails_odbc"

miscFiles = [
 "install_odbc.rb",
 "pack_odbc.rb",
 "readme.html"
]

# Stems of new .sql files added to $AR_DEV_ROOT/test/fixtures/db_definitions
# !! UPDATE AS SUPPORT FOR OTHER DATABASES IS ADDED TO ODBC ADAPTER
wantedBasenamePrefixes = [
 "informix", "ingres", "virtuoso", "oracle_odbc"
]

# Files in public ActiveRecord source tree which have been modified for 
# ODBC adapter    
modifiedFiles = [
  "./test/base_test.rb",
  "./test/migration_test.rb",
  "./lib/active_record/connection_adapters/abstract/schema_definitions.rb"
]

raise Exception, "Directory doesn't exist: #{$AR_DEV_ROOT}" if !File.exist?($AR_DEV_ROOT)

# Create directory tree under $PACK_ROOT
FileUtils.mkdir_p($PACK_ROOT)
FileUtils.mkdir_p(File.join($PACK_ROOT, 'new_files/lib/active_record/connection_adapters'))
FileUtils.mkdir_p(File.join($PACK_ROOT, 'new_files/lib/active_record/vendor'))
FileUtils.mkdir_p(File.join($PACK_ROOT, 'new_files/test/fixtures/db_definitions'))
FileUtils.mkdir_p(File.join($PACK_ROOT, 'new_files/test/connections/native_odbc'))
FileUtils.mkdir_p(File.join($PACK_ROOT, 
    'modified_files/lib/active_record/connection_adapters/abstract'))
FileUtils.mkdir_p(File.join($PACK_ROOT, 'modified_files/test'))

# Generate RDoc's
Dir.glob($AR_DEV_ROOT + "/**/odbc_adapter.rb") { |f|
  FileUtils.cp(f, $PACK_ROOT)
  Dir.chdir($PACK_ROOT)
  FileUtils.rmtree('doc')
  r = RDoc::RDoc.new
  r.document(['-q', 'odbc_adapter.rb'])
  FileUtils.rm('odbc_adapter.rb')
}

# Copy new files into $PACK_ROOT
# i.e. files not in the current ActiveRecord distribution
Dir.chdir($AR_DEV_ROOT)
Find.find(".") { |f|
  if File.fnmatch("./**/odbc*.rb" , f)
    FileUtils.cp(f, File.join($PACK_ROOT, "new_files", *f.split(/\//)),
    :verbose => true)
  end
}  

f = "./test/connections/native_odbc/connection.rb"
FileUtils.cp(f, File.join($PACK_ROOT, "new_files", *f.split(/\//)),
    :verbose => true)

Find.find(".") { |f|
  if File.fnmatch("./**/*.sql" , f)
    basename = File.basename(f, ".sql")
    wantedBasenamePrefixes.each do |prefix|
      if basename.match("^#{prefix}")
        FileUtils.cp(f, File.join($PACK_ROOT, "new_files", *f.split(/\//)),
            :verbose => true)
      end
    end
  end
}  

modifiedFiles.each do |f|
  FileUtils.cp(f, File.join($PACK_ROOT, "modified_files", *f.split(/\//)),
      :verbose => true)
end

miscFiles.each do |f|
  FileUtils.cp(File.join($MISC_ROOT, f), $PACK_ROOT, :verbose => true)
end
