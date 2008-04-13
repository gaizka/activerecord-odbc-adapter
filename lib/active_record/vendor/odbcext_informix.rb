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
    @logger.unknown("ODBCAdapter#last_insert_id>") if @trace
    @logger.unknown("args=[#{table}]") if @trace    
    # 1049 (SQL_LASTSERIAL) is an ODBC extension for SQLGetStmtOption  
    stmt.get_option(1049)
  end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.  

  def type_to_sql(type, limit = nil, precision = nil, scale = nil)
    if type == :decimal
      # Force an explicit scale if none supplied to specify the fixed
      # point form of Informix's DECIMAL type. If no scale is specified,
      # the Informix DECIMAL type stores floating point values.
      precision ||= 32
      scale ||= 0
    end
    super(type, limit, precision, scale)
  end
  
  def quoted_date(value)
    @logger.unknown("ODBCAdapter#quoted_date>") if @trace
    @logger.unknown("args=[#{value}]") if @trace
    # Informix's DBTIME and DBDATE environment variables should be set to:
    # DBTIME=%Y-%m-%d %H:%M:%S
    # DBDATE=Y4MD-
    if value.acts_like?(:time) # Time, DateTime
      %Q!'#{value.strftime("%Y-%m-%d %H:%M:%S.")}'!
    else # Date
      %Q!'#{value.strftime("%Y-%m-%d")}'!
    end
  end
  
  def rename_table(name, new_name)
    @logger.unknown("ODBCAdapter#rename_table>") if @trace
    @logger.unknown("args=[#{name}|#{new_name}]") if @trace    
    execute "RENAME TABLE #{name} TO #{new_name}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def change_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#change_column>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}|#{type}]") if @trace
    change_column_sql = "ALTER TABLE #{table_name} MODIFY #{column_name} " +
        "#{type_to_sql(type, options[:limit], options[:precision], options[:scale])}" 
    # Add any :null and :default options
    add_column_options!(change_column_sql, options)
    execute(change_column_sql)    
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def change_column_default(table_name, column_name, default)
    @logger.unknown("ODBCAdapter#change_column_default>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}]") if @trace
    col = columns(table_name).find {|c| c.name == column_name.to_s }
    change_column(table_name, column_name, col.type, :default => default,
      :limit => col.limit, :precision => col.precision, :scale => col.scale)
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def rename_column(table_name, column_name, new_column_name)
    @logger.unknown("ODBCAdapter#rename_column>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}|#{new_column_name}]") if @trace    
    execute "RENAME COLUMN #{table_name}.#{column_name} TO #{new_column_name}"
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
    # Hide the system tables. Some contain columns which don't have an 
    # equivalent ODBC SQL type which causes problems with #columns.
    super(name).delete_if {|t| t =~ /^sys/i }
  end
  
  def indexes(table_name, name = nil)
    # Informix creates a unique index for a table's primary key.
    # Hide any such index. The index name takes the form ddd_ddd.
    # (Indexes created through 'CREATE INDEX' must have a name starting
    # with a letter or an # underscore.)
    #
    # If this isn't done...
    # Rails' 'rake test_units' attempts to create primary key indexes 
    # explicitly when creating the test database schema. Informix rejects
    # the resulting 'CREATE UNIQUE INDEX ddd_ddd' commands with a syntax
    # error.
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /\d+_\d+/ }
  end
  
end # module
