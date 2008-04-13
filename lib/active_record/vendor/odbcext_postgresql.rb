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

module ODBCExt
  
  # ------------------------------------------------------------------------
  # Mandatory methods
  #
  
  # #last_insert_id must be implemented for any database which returns
  # false from #prefetch_primary_key?

  def last_insert_id(table, sequence_name, stmt = nil)
    select_value("select currval('#{sequence_name}')", 'last_insert_id')
  end
  
  # ------------------------------------------------------------------------
  # Optional methods
  #
  # These are supplied for a DBMS only if necessary.
  # ODBCAdapter tests for optional methods using Object#respond_to?

  # Filter for ODBCAdapter#tables
  # Omits table from #tables if table_filter returns true
  def table_filter(schemaName, tblName, tblType)
    ["information_schema", "pg_catalog"].include?(schemaName) || tblType !~ /TABLE/i
  end
  
  # Pre action for ODBCAdapter#insert
  # def pre_insert(sql, name, pk, id_value, sequence_name)
  # end
  
  # Post action for ODBCAdapter#insert
  # def post_insert(sql, name, pk, id_value, sequence_name)
  # end
  
  def string_to_binary(value)
    # Escape data prior to insert into a bytea column
    if value
      res = ''
      value.each_byte { |b| res << sprintf('\\\\%03o', b) }
      res
    end
  end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.  
  
  def quoted_true
    "'t'"
  end
      
  def quoted_false
    "'f'"
  end
      
  def quote_string(string)
    @logger.unknown("ODBCAdapter#quote_string>") if @trace    
    string.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end
  
  def default_sequence_name(table, column)
    @logger.unknown("ODBCAdapter#default_sequence_name>") if @trace
    @logger.unknown("args=[#{table}|#{column}]") if @trace
    "#{table}_#{column}_seq"      
  end

  def indexes(table_name, name = nil)
    # Exclude primary key indexes
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /_pkey$/i }
  end

  def rename_table(name, new_name)
    @logger.unknown("ODBCAdapter#rename_table>") if @trace
    execute "ALTER TABLE #{name} RENAME TO #{new_name}"          
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def add_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#add_column>") if @trace
    sql = "ALTER TABLE #{table_name} ADD #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
    sql << " NOT NULL" if options[:null] == false
    sql << " DEFAULT #{quote(options[:default])}" if options[:default]
    execute(sql)
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#change_column>") if @trace
    execute "ALTER TABLE #{table_name} ALTER  #{column_name} TYPE #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
    change_column_default(table_name, column_name, options[:default]) if options_include_default?(options)
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column_default(table_name, column_name, default)
    @logger.unknown("ODBCAdapter#change_column_default>") if @trace
    execute "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET DEFAULT #{quote(default)}"        
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def rename_column(table_name, column_name, new_column_name)
    @logger.unknown("ODBCAdapter#rename_column>") if @trace
    execute "ALTER TABLE #{table_name} RENAME #{column_name} TO #{new_column_name}"                
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def remove_index(table_name, options = {})
    @logger.unknown("ODBCAdapter#remove_index>") if @trace
    execute "DROP INDEX #{index_name(table_name, options)}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def disable_referential_integrity(&block) #:nodoc:
    execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} DISABLE TRIGGER ALL" }.join(";"))
    yield
  ensure
    execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} ENABLE TRIGGER ALL" }.join(";"))
  end
  
end # module
