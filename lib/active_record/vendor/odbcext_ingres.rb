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

require 'active_record/connection_adapters/abstract_adapter'

module ODBCExt
  
  # ------------------------------------------------------------------------
  # Mandatory methods
  #

  # #last_insert_id must be implemented for any database which returns
  # false from #prefetch_primary_key?
  # (This adapter returns true for Ingres)
  
  #def last_insert_id(table, sequence_name, stmt = nil)
  #end
  
  # #next_sequence_value must be implemented for any database which returns
  # true from #prefetch_primary_key?
  #
  # Returns the next sequence value from a sequence generator. Not generally
  # called directly; used by ActiveRecord to get the next primary key value
  # when inserting a new database record (see #prefetch_primary_key?).
  def next_sequence_value(sequence_name)
    @logger.unknown("ODBCAdapter#next_sequence_value>") if @trace
    @logger.unknown("args=[#{sequence_name}]") if @trace
    select_one("select #{sequence_name}.nextval id")['id']
  end
  
  # ------------------------------------------------------------------------
  # Optional methods
  #
  # These are supplied for a DBMS only if necessary.
  # ODBCAdapter tests for optional methods using Object#respond_to?
  
  # Pre action for ODBCAdapter#insert
  # def pre_insert(sql, name, pk, id_value, sequence_name)
  # end
  
  # Post action for ODBCAdapter#insert
  # def post_insert(sql, name, pk, id_value, sequence_name)
  # end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.
  
  def create_table(name, options = {})
    @logger.unknown("ODBCAdapter#create_table>") if @trace
    @logger.unknown("args=[#{name}]") if @trace
    #ALTER TABLE ADD COLUMN not allowed with default page size of 2K
    super(name, {:options => "WITH PAGE_SIZE=8192"}.merge(options))
    execute "CREATE SEQUENCE #{name}_seq"          
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end
  
  def drop_table(name, options = {})
    @logger.unknown("ODBCAdapter#drop_table>") if @trace
    @logger.unknown("args=[#{name}]") if @trace
    super(name, options)
    execute "DROP SEQUENCE #{name}_seq"          
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end
  
  def add_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#add_column>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}]") if @trace
    
    sql = "ALTER TABLE #{quote_table_name(table_name)} ADD #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
    sql << " DEFAULT #{quote(options[:default], options[:column])}" unless options[:default].nil?

    # Ingres requires that if 'ALTER TABLE table ADD column' specifies a NOT NULL constraint,
    # then 'WITH DEFAULT' must also be specified *without* a default value.
    # Ingres will report an error if both options[:null] == false && options[:default]
    if options[:null] == false
      sql << " NOT NULL"
      sql << " WITH DEFAULT" if options[:default].nil?
    end
    execute(sql)
    rescue Exception => e
      @logger.unknown("exception=#{e}") if @trace
      raise ActiveRecord::ActiveRecordError, e.message
  end

  def remove_column(table_name, column_name)
    @logger.unknown("ODBCAdapter#remove_column>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}]") if @trace
    execute "ALTER TABLE #{quote_table_name(table_name)} DROP #{quote_column_name(column_name)} RESTRICT"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def change_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#change_column>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}|#{type}]") if @trace
    change_column_sql = "ALTER TABLE #{table_name} ALTER #{column_name} " +
        "#{type_to_sql(type, options[:limit], options[:precision], options[:scale])}" 
    # Add any :null and :default options
    add_column_options!(change_column_sql, options)
    execute(change_column_sql)    
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end
      
  def remove_index(table_name, options = {})
    @logger.unknown("ODBCAdapter#remove_index>") if @trace
    @logger.unknown("args=[#{table_name}]") if @trace
    execute "DROP INDEX #{quote_column_name(index_name(table_name, options))}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def tables(name = nil)
    # Hide system tables
    super(name).delete_if {|t| t =~ /^ii/i }
  end

  def indexes(table_name, name = nil)
    # Hide internally generated indexes used to support primary keys.
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /^\$/ }
  end

end # module
