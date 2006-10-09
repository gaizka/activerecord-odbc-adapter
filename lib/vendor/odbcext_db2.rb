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
    select_value("VALUES IDENTITY_VAL_LOCAL()", 'last_insert_id')    
  end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.  

  def rename_table(name, new_name)
    @logger.unknown("ODBCAdapter#rename_table>") if @trace
    @logger.unknown("args=[#{name}|#{new_name}]") if @trace    
    execute "RENAME TABLE #{name} TO #{new_name}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def change_column_default(table_name, column_name, default)
    @logger.unknown("ODBCAdapter#change_column_default>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}]") if @trace    
    execute "ALTER TABLE #{table_name} ALTER #{column_name} SET DEFAULT #{quote(default)}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def remove_column(table_name, column_name)
    @logger.unknown("ODBCAdapter#remove_column>\n" +
                    "args=[#{table_name}|#{column_name}]\n" + 
                    "exception=remove_column is not supported") if @trace
    raise ActiveRecord::ActiveRecordError, "remove_column is not supported"
  end

  def remove_index(table_name, options = {})
    @logger.unknown("ODBCAdapter#remove_index>") if @trace
    @logger.unknown("args=[#{table_name}]") if @trace    
    execute "DROP INDEX #{quote_column_name(index_name(table_name, options))}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end

  def indexes(table_name, name = nil)
    # Hide primary key indexes
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /^sql\d+$/ }
  end
  
  def structure_dump #:nodoc:
    raise NotImplementedError, "structure_dump is not implemented"
  end      
end # module
