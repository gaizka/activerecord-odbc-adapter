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

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/rdoctask'

#
#  Package meta information
#
PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'rails-odbc'
PKG_VERSION   = '1.0'
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"


#
#  File list for distribution purposes
#
PKG_FILES = FileList[
  "AUTHORS",
  "COPYING",
  "ChangeLog",
  "LICENSE",
  "NEWS",
  "README",
  "Rakefile",
  "*.rb",
  "lib/**/*.rb", 
  "doc/**/*",
  "support/**/*",
  "test/**/*.rb"
].exclude(/\bCVS\b|~$/)


#
#  Default task
#
desc 'Default: generate documentation.'
task :default => :rdoc


#
#  Generate documentation
#
desc 'Generate documentation for the OpenLink ODBC Adapter for Ruby on Rails.'
Rake::RDocTask.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = 'doc'
    rdoc.title    = 'OpenLink ODBC Adapter for Ruby on Rails'
    rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'README'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('COPYING')
    rdoc.rdoc_files.include('lib/connection_adapters/*.rb')
end


#
#  Install package
#
desc "Install package"
task :install do
  ruby "install_odbc.rb"
end


#
#  Generate distribution package
#
desc 'Generate package for distribution.'
Rake::PackageTask.new(PKG_NAME, PKG_VERSION) do |p|
    p.need_tar = true
    p.need_zip = true
    p.package_dir = 'distrib'
    p.package_files.include(PKG_FILES)
end

#
#  Cleanup
#
CLEAN.include('doc/**')
CLEAN.include('distrib/**')
