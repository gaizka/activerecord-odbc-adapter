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
    #TODO: Fixme - Doesn't work with OpenLink TDS driver against Sybase
    #select_value("select @@IDENTITY", 'last_insert_id')
    select_value("select max(syb_identity) from #{table}", 'last_insert_id')
  end
  
  # ------------------------------------------------------------------------
  # Optional methods
  #
  # These are supplied for a DBMS only if necessary.
  # ODBCAdapter tests for optional methods using Object#respond_to?
  
  # Pre action for ODBCAdapter#insert
  def pre_insert(sql, name, pk, id_value, sequence_name)
    @iiTable = get_table_name(sql)
    @iiCol = get_autounique_column(@iiTable)
    @iiEnabled = false
    
    if @iiCol != nil
      if query_contains_autounique_col(sql, @iiCol)
        begin
          @connection.do(enable_identity_insert(@iiTable, true))
          @iiEnabled = true
        rescue Exception => e
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned on"
        end
      end
    end
  end
  
  # Post action for ODBCAdapter#insert
  def post_insert(sql, name, pk, id_value, sequence_name)
    if @iiEnabled
      begin
        @connection.do(enable_identity_insert(@iiTable, false))
      rescue Exception => e
        raise ActiveRecordError, "IDENTITY_INSERT could not be turned off"
      end
    end
  end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.
  
  def rename_table(name, new_name)
    @logger.unknown("ODBCAdapter#rename_table>") if @trace
    execute "EXEC sp_rename '#{name}', '#{new_name}'"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def remove_column(table_name, column_name)
    @logger.unknown("ODBCAdapter#remove_column>") if @trace
    # Remove default constraints first
    defaults = select_all "select def.name from sysobjects def, syscolumns col, sysobjects tab where col.cdefault = def.id and col.name = '#{column_name}' and tab.name = '#{table_name}' and col.id = tab.id"
    defaults.each {|constraint|
      execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{constraint["name"]}"
    }                      
    execute "ALTER TABLE #{quote_table_name(table_name)} DROP #{quote_column_name(column_name)}"                   
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#change_column>") if @trace
    if options.include?(:default)
      # Sybase ASE's ALTER TABLE statement doesn't allow a column's DEFAULT to be changed.
      raise ActiveRecord::ActiveRecordError, 
        "Sybase ASE does not support changing a column's DEFAULT definition"
    end
    execute "ALTER TABLE #{table_name} MODIFY #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def rename_column(table_name, column_name, new_column_name)
    @logger.unknown("ODBCAdapter#rename_column>") if @trace
    execute "EXEC sp_rename '#{table_name}.#{column_name}', '#{new_column_name}'"        
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def remove_index(table_name, options = {})
    @logger.unknown("ODBCAdapter#remove_index>") if @trace
    execute "DROP INDEX #{table_name}.#{quote_column_name(index_name(table_name, options))}"        
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def tables(name = nil)
    # Hide system tables.
    super(name).delete_if {|t| t =~ /^sys/ }
  end
  
  def indexes(table_name, name = nil)
    # Hide primary key indexes.
    # Primary key indexes take the form <tablename>_<primary key name>_<integer>
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /^\w+_\w+_\d+$/ }
  end
  
  def add_column_options!(sql, options) # :nodoc:
    @logger.unknown("ODBCAdapter#add_column_options!>") if @trace
    @logger.unknown("args=[#{sql}]") if @trace
    sql << " DEFAULT #{quote(options[:default], options[:column])}" if options_include_default?(options)
    
    if column_type_allows_null?(sql, options)
      sql << (options[:null] == false ? " NOT NULL" : " NULL")
    end
    sql   																											
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::StatementInvalid, e.message
  end
  
  # ------------------------------------------------------------------------
  # Private methods to support methods above
  #
  private
  
  def get_table_name(sql)
    if sql =~ /^\s*insert\s+into\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
      $1
    elsif sql =~ /from\s+([^\(\s]+)\s*/i
      $1
    else
      nil
    end	end
  
  def get_autounique_column(table_name)
    @table_columns = {} unless @table_columns
    @table_columns[table_name] = columns(table_name) if @table_columns[table_name] == nil
    @table_columns[table_name].each do |col|
      return col.name if col.auto_unique?
    end
    
    return nil
  end
  
  def query_contains_autounique_col(sql, col)
    sql =~ /(\[#{col}\])|("#{col}")/
  end
  
  def enable_identity_insert(table_name, enable = true)
    if has_autounique_column(table_name)
    	"SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}"
    end
  end
  
  def has_autounique_column(table_name)
    !get_autounique_column(table_name).nil?
  end
  
  def column_type_allows_null?(sql, options)
    # Sybase columns are NOT NULL by default, so explicitly set NULL
    # if :null option is omitted.  Disallow NULLs for boolean.
    col = options[:column]
    return false if col && col[:type] == :primary_key
    
    # Force options[:null] to be ignored for BIT (:boolea) columns
    # by returning false
    isBitCol = !(sql =~ /\s+bit(\s+default)?/i).nil? || (col && col[:type] == :boolean)
    hasDefault = !$1.nil? || options[:default]
    
    # If no default clause found on a boolean column, add one.
    sql << " DEFAULT 0" if isBitCol && !hasDefault
    
    !isBitCol
  end
  
end # module
