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
    select_value("select @@IDENTITY", 'last_insert_id')
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
  
   
end # module
