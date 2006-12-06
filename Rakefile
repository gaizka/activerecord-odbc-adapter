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

require 'rubygems'
Gem::manage_gems

require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/packagetask'
require 'rake/rdoctask'
require "support/rake/rails_plugin_package_task"


#
#  Package meta information
#
PKG_NAME     = 'odbc-rails'
PKG_SUMMARY  = "ODBC Data Adapter for ActiveRecord."
PKG_VERSION  = '1.2'
PKG_HOMEPAGE = 'http://odbc-rails.rubyforge.org'
PKG_AUTHOR = "Carl Blakeley"
PKG_AUTHOR_EMAIL = "cblakeley@openlinksw.co.uk"


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
  "lib/**/*", 
  "rdoc/**/*",
  "rake/**/*",
  "support/**/*",
  "test/**/*"
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
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'OpenLink ODBC Adapter for Ruby on Rails'
    rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'README'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('COPYING')
    rdoc.rdoc_files.include('lib/active_record/connection_adapters/*.rb')
end

#
#  Generate gem
#
spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.author = PKG_AUTHOR
  s.email = PKG_AUTHOR_EMAIL
  s.homepage = PKG_HOMEPAGE
  s.platform = Gem::Platform::RUBY
  s.summary = PKG_SUMMARY
  s.files = FileList["{lib,test,support}/**/*", "AUTHORS", "ChangeLog", "COPYING", "LICENSE", "NEWS", "README"].to_a
  s.require_path = "lib"
  s.autorequire = "odbc_adapter"
  s.has_rdoc = true
  s.rdoc_options << '--title' << 'OpenLink ODBC Adapter for Ruby on Rails' <<
                    '--line-numbers' << 
                    '--inline-source' <<
                    '--main' << 'README' <<
                    '--exclude' << 'lib/odbc_adapter.rb' <<
                    '--exclude' << 'pack_odbc.rb' <<
                    '--exclude' << 'vendor' <<
                    '--exclude' << 'support' <<
                    '--exclude' << 'test' <<
                    '--include' << 'active_record/connection_adapters/*.rb'
  s.extra_rdoc_files = ["README", "COPYING"]
end
Rake::GemPackageTask.new(spec) do |p|
  p.package_dir = "distrib"
end

desc "Build odbc-rails gem"
task :build_gem => ["distrib/#{PKG_NAME}-#{PKG_VERSION}.gem"]

#
#  Install package into ActiveRecord tree
#
desc "Install package into ActiveRecord tree"
task :install do
  ruby "install_odbc.rb"
end


#
#  Configure plugin
#
desc "Configure plugin (required only if plugin was \n\t\t\t" +
     " manually unpacked into vendor/plugins)"
task :configure_plugin do
  begin
    ruby "install.rb"
  rescue
    puts <<-MSG 
      Run this task from the vendor/plugins/#{PKG_NAME}_#{PKG_VERSION} 
      folder of your Rails application.
      MSG
  end
end

#
#  Generate distribution tar and zip packages
#
Rake::PackageTask.new(PKG_NAME, PKG_VERSION) do |p|
    p.need_tar = true
    p.need_zip = true
    p.package_dir = 'distrib'
    p.package_files.include(PKG_FILES)
end


#
# Generate plugin package
#
Rake::RailsPluginPackageTask.new(PKG_NAME, PKG_VERSION) do |p|
  p.package_dir = "distrib_plugin"
  p.package_files = PKG_FILES
  p.extra_links = {"Project home page"=>PKG_HOMEPAGE}
  p.verbose = true
end


#
#  Cleanup
#
CLEAN.include('rdoc')
CLEAN.include('distrib')
CLEAN.include('distrib_plugin')
