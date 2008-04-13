#
#  $Id$
#
#  OpenLink ODBC Adapter for Ruby on Rails
#  Extension module for Progress v9 and later using SQL-92 engine
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
  # (This adapter returns true for Progress)
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
    #@logger.unknown("args=[#{sequence_name}]") if @trace
    select_one("select PUB.#{sequence_name}.NEXTVAL from SYSPROGRESS.SYSCALCTABLE")['sequence_next']
  end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.  
  
  def quote_column_name(name)
    @logger.unknown("ODBCAdapter#quote_column_name>") if @trace
    @logger.unknown("args=[#{name}]") if @trace        
    name = name.to_s if name.class == Symbol                
    idQuoteChar = @dsInfo.info[ODBC::SQL_IDENTIFIER_QUOTE_CHAR]
        
    return name if !idQuoteChar || ((idQuoteChar = idQuoteChar.strip).length == 0)
    idQuoteChar = idQuoteChar[0]
    
    # Avoid quoting any already quoted name
    return name if name[0] == idQuoteChar && name[-1] == idQuoteChar
    
    # If a DBMS's SQL_IDENTIFIER_CASE is SQL_IC_UPPER, this adapter's base 
    # implementation of #quote_column_name only quotes mixed case names.
    # But for Progress v9 or later, for which we force SQL_IDENTIFIER_CASE to
    # SQL_IC_UPPER (see DSInfo#new), we want to quote *ALL* column names. 
    # This is done because many of the Rails tests and fixtures use a column
    # named 'type', but type is a reserved word in Progress SQL. Progress 9
    # accepts the quoting of all column names because its 
    # SQL_QUOTED_IDENTIFIER_CASE behaviour is SQL_IC_MIXED.
    idQuoteChar.chr + name + idQuoteChar.chr
  end
  
  def create_table(name, options = {})
    @logger.unknown("ODBCAdapter#create_table>") if @trace
    super(name, options)
    # Some ActiveRecord tests insert using an explicit id value. Starting the
    # primary key sequence from 10000 eliminates collisions (and subsequent
    # complaints from Progress of integrity constraint violations) between id's 
    # generated from the sequence and explicitly supplied ids.
    # Using explicit and generated id's together should be avoided.
    # 
    # Currently, OpenEdge only supports sequences in the PUBLIC (PUB) schema.
    execute "CREATE SEQUENCE PUB.#{name}_seq MINVALUE 10000" unless options[:id] == false          
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end
  
  def drop_table(name, options = {})
    @logger.unknown("ODBCAdapter#drop_table>") if @trace
    super(name, options)
    execute "DROP SEQUENCE PUB.#{name}_seq"          
  rescue Exception => e
    if e.message !~ /10520/
      # Error "Sequence not found. (10520)" will be generated
      # if the table was created with options[:id] == false
      @logger.unknown("exception=#{e}") if @trace
      raise ActiveRecord::ActiveRecordError, e.message
    end
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
    @logger.unknown("ODBCAdapter#remove_column>") if @trace
    # Although this command is documented in the OpenEdge SQL Reference,
    # it returns error -20024 ("Sorry, operation not yet implemented").
    execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message
  end
    
  def tables(name = nil)
    # Hide system tables.
    super(name).delete_if {|t| t =~ /^sys/i }
  end
  
  def indexes(table_name, name = nil)
    # Hide primary key indexes
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /^sys/i }
  end
  
end # module
