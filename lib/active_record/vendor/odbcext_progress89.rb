#
#  $Id$
#
#  OpenLink ODBC Adapter for Ruby on Rails
#  Extension module for Progress v8 and earlier using SQL-89 engine
#  
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
    sequence_next_val(sequence_name.to_s)
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message    
  end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.  
  
  # Progress SQL89 requires that the DEFAULT specification *follows* 
  # any NOT NULL constraint.
  def add_column_options!(sql, options) #:nodoc:
    @logger.unknown("ODBCAdapter#add_column_options!>") if @trace
    @logger.unknown("args=[#{sql}]") if @trace
    sql << " NOT NULL" if options[:null] == false
    # Progress 89 doesn't accept 'DEFAULT NULL'
    sql << " DEFAULT #{quote(options[:default], options[:column])}" if options_include_default?(options) && !options[:default].nil?
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise StatementInvalid, e.message
  end
  
  def quote_column_name(name)
    @logger.unknown("ODBCAdapter#quote_column_name>") if @trace
    @logger.unknown("args=[#{name}]") if @trace        
    # Progress v8 or earlier doesn't support quoted identifiers.
    # ODBC::SQL_IDENTIFIER_QUOTE_CHAR is typically " "
    name.to_s
  end
  
  def quoted_date(value)
    @logger.unknown("ODBCAdapter#quoted_date>") if @trace
    @logger.unknown("args=[#{value}]") if @trace       
      # Progress v8 doesn't support a datetime or time type,
      # only a date type.
      if value.acts_like?(:time) # Time, DateTime
        #%Q!{ts '#{value.strftime("%Y-%m-%d %H:%M:%S")}'}!          
        %Q!{d '#{value.strftime("%Y-%m-%d")}'}!
      else # Date
        %Q!{d '#{value.strftime("%Y-%m-%d")}'}!
      end
  end

  # Progress SQL-89 doesn't support column aliases
  # Strip 'AS <alias>' from all selects
 
  def select_all(sql, name = nil)   
    super(remove_select_column_aliases(sql), name)
  end
  
  def select_one(sql, name = nil)
    super(remove_select_column_aliases(sql), name)
  end
  
  def select_value(sql, name = nil)
    super(remove_select_column_aliases(sql), name)
  end
  
  def select_values(sql, name = nil)
    super(remove_select_column_aliases(sql), name)
  end

  def indexes(table_name, name = nil)
    # Hide primary key indexes
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /^sql/ }
  end
  
  def create_table(name, options = {})
    @logger.unknown("ODBCAdapter#create_table>") if @trace
    super(name, options)
    # Some ActiveRecord tests insert using an explicit id value. Starting the
    # primary key sequence from 10000 eliminates collisions (and subsequent
    # complaints from Progress of integrity constraint violations) between id's 
    # generated from the sequence and explicitly supplied ids.
    # Using explicit and generated id's together should be avoided.
    create_sequence("#{name}_seq", 10000) unless options[:id] == false
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message    
  end
  
  def drop_table(name, options = {})
    @logger.unknown("ODBCAdapter#drop_table>") if @trace
    super(name, options)
    drop_sequence("#{name}_seq")
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message    
  end

  def change_column_default(table_name, column_name, default)
    @logger.unknown("ODBCAdapter#change_column_default>") if @trace
    @logger.unknown("args=[#{table_name}|#{column_name}]") if @trace    
    execute "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} DEFAULT #{quote(default)}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message    
  end
  
  def remove_column(table_name, column_name)
    @logger.unknown("ODBCAdapter#remove_column>") if @trace
    # Although this command is documented in the Progress SQL Reference,
    # it returns error 247 ('Unable to understand after -- "alter") if
    # executed via the ODBC driver. (Executing the same command through 
    # the Procedure Editor works)
    execute "ALTER TABLE #{table_name} DROP COLUMN #{column_name}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message    
  end
  
  def remove_index(table_name, options = {})
    @logger.unknown("ODBCAdapter#remove_index>") if @trace
    execute "DROP INDEX #{index_name(table_name, options)}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise ActiveRecord::ActiveRecordError, e.message    
  end
  
private

  def remove_select_column_aliases(sql)
    sql.gsub(/\s+as\s+\w+/i, '')
  end
  
  # ------------------------------------------------------------------------
  # Sequence simulation
  # 
  # It appears a native Progress (<= v8) sequence can only be created
  # using the Data Dictionary tool, not through SQL89 DDL. Also, there's no
  # way to retrieve a native sequence's next value through SQL89.
  # Instead of using Progress's built-in sequences, we simulate them.
 
  SEQ_DFLT_START_VAL = 10000
  SEQS_DFLT_TBL_NAME = "railsseqs"
  @@seqs_table_exists = false

  # Creates a simulated sequence
  def create_sequence(name, start_val = SEQ_DFLT_START_VAL)
    raise ActiveRecordError, "sequence start value <= 0" if start_val <= 0
    ensure_sequences_table unless @@seqs_table_exists
    sql = "INSERT INTO #{SEQS_DFLT_TBL_NAME}(SEQ_NAME, SEQ_NEXT_VAL) VALUES ('#{name.upcase}', #{start_val})"
    @connection.do(sql)
  end
      
  # Drops a simulated sequence
  def drop_sequence(name)
    begin
      sql = "DELETE FROM #{SEQS_DFLT_TBL_NAME} WHERE SEQ_NAME = '#{name.upcase}'"
      @connection.do(sql)
    rescue Exception => e
      # Tables may be created without an accompanying sequence if 
      # #create_table wasn't used to create the table or :id => false was
      # specified. So, the sequence table may not exist. Trap error 962:
      #   "Table <sequence table name> does not exist or cannot be accessed"
      raise unless e.message =~ /962/
    end
  end
    
  def sequence_next_val(name)
    begin
      begin_db_transaction
      sql = "SELECT SEQ_NEXT_VAL FROM #{SEQS_DFLT_TBL_NAME} WHERE SEQ_NAME = '#{name.upcase}'"
      sql << " FOR UPDATE"
      next_val = select_value(sql, 'next_sequence_value')
      if next_val.nil?
        # The table doesn't yet have an accompanying sequence.
        # Assume the table was created using #execute('CREATE TABLE...') 
        # instead of #create_table. (Rails uses the former method when
        # creating the test database schema from the development database.)

        # Progress commits DDL immediately, ending the current transaction
        commit_db_transaction
        create_sequence(name)
        begin_db_transaction
        next_val = SEQ_DFLT_START_VAL
      end      
      sql = "UPDATE #{SEQS_DFLT_TBL_NAME} SET SEQ_NEXT_VAL = SEQ_NEXT_VAL + 1 "
      sql << "WHERE SEQ_NAME = '#{name.upcase}'"
      @connection.do(sql)
      commit_db_transaction
    rescue Exception => e
      if e.message =~ /962/
        # Sequence table doesn't exist yet. Can happen if tables are created
        # using #execute instead of #create_table.
        rollback_db_transaction
        ensure_sequences_table
        retry
      end
      rollback_db_transaction
      raise      
    end
    
    next_val
  end
      
  def ensure_sequences_table
    unless tables(SEQS_DFLT_TBL_NAME).include?(SEQS_DFLT_TBL_NAME)
      sql = "CREATE TABLE #{dbmsIdentCase(SEQS_DFLT_TBL_NAME)} ("
      sql << "SEQ_NAME CHARACTER(32) NOT NULL UNIQUE, "
      sql << "SEQ_NEXT_VAL INTEGER NOT NULL DEFAULT #{SEQ_DFLT_START_VAL})"
      @connection.do(sql)
    end
    @@seq_table_exists = true
  end
    
end # module
