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
  # (This adapter returns true for Oracle)
  
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
    select_one("select #{sequence_name}.nextval id from dual")['id']
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
  
  def quoted_date(value)
    @logger.unknown("ODBCAdapter#quoted_date>") if @trace
    # Ideally, we'd return an ODBC date or timestamp literal escape 
    # sequence, but not all ODBC drivers support them.
    if value.acts_like?(:time) # Time, DateTime
      #%Q!{ts '#{value.strftime("%Y-%m-%d %H:%M:%S")}'}!
      "to_timestamp(\'#{value.strftime("%Y-%m-%d %H:%M:%S")}\', \'YYYY-MM-DD HH24:MI:SS\')"
    else # Date
      #%Q!{d '#{value.strftime("%Y-%m-%d")}'}!
      "to_timestamp(\'#{value.strftime("%Y-%m-%d")}\', \'YYYY-MM-DD\')"
    end
  end
  
  def create_table(name, options = {})
    @logger.unknown("ODBCAdapter#create_table>") if @trace
    super(name, options)
    # Some ActiveRecord tests insert using an explicit id value. Starting the
    # primary key sequence from 10000 eliminates collisions (and subsequent
    # complaints from Oracle of integrity constraint violations) between id's 
    # generated from the sequence and explicitly supplied ids.
    # Using explicit and generated id's together should be avoided.
    execute "CREATE SEQUENCE #{name}_seq START WITH 10000" unless options[:id] == false          
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def rename_table(name, new_name)
    @logger.unknown("ODBCAdapter#rename_table>") if @trace
    execute "RENAME #{name} TO #{new_name}"
    execute "RENAME #{name}_seq TO #{new_name}_seq"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def drop_table(name, options = {})
    @logger.unknown("ODBCAdapter#drop_table>") if @trace
    super(name, options)
    execute "DROP SEQUENCE #{name}_seq"          
  rescue Exception => e
    if e.message !~ /ORA-02289/i
      # Error "ORA-02289: sequence does not exist" will be generated
      # if the table was created with options[:id] == false
      @logger.unknown("exception=#{e}") if @trace
      raise
    end
  end
  
  def remove_column(table_name, column_name)
    @logger.unknown("ODBCAdapter#remove_column>") if @trace
    execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end

  def change_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#change_column>") if @trace
    change_column_sql = "ALTER TABLE #{table_name} MODIFY #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
    add_column_options!(change_column_sql, options)
    execute(change_column_sql)
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column_default(table_name, column_name, default)
    @logger.unknown("ODBCAdapter#change_column_default>") if @trace
    execute "ALTER TABLE #{table_name} MODIFY #{column_name} DEFAULT #{quote(default)}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def rename_column(table_name, column_name, new_column_name)
    @logger.unknown("ODBCAdapter#rename_column>") if @trace
    execute "ALTER TABLE #{table_name} RENAME COLUMN #{column_name} to #{new_column_name}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def remove_index(table_name, options = {})
    @logger.unknown("ODBCAdapter#remove_index>") if @trace
    execute "DROP INDEX #{quote_column_name(index_name(table_name, options))}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def tables(name = nil)
    # Hide dropped tables in Oracle's recyclebin. 
    super(name).delete_if {|t| t =~ /^BIN\$/i }
  end
  
  def indexes(table_name, name = nil)
    # Oracle creates a unique index for a table's primary key.
    # Hide any such index. Oracle uses system-generated names 
    # beginning with "SYS_" for implicitly generated schema objects.
    #
    # If this isn't done...
    # Rails' 'rake test_units' attempts to create this index explicitly,
    # but Oracle rejects this as the index has already been created 
    # automatically when the table was defined.
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /^SYS_/i }
  end
  
  def structure_dump
    @logger.unknown("ODBCAdapter#structure_dump>") if @trace
    s = select_all("select sequence_name from user_sequences").inject("") do |structure, seq|
      structure << "create sequence #{seq.to_a.first.last};\n\n"
    end
    
    select_all("select table_name from user_tables").inject(s) do |structure, table|
      ddl = "create table #{table.to_a.first.last} (\n "  
      cols = select_all(%Q{
              select column_name, data_type, data_length, data_precision, data_scale, data_default, nullable
              from user_tab_columns
              where table_name = '#{table.to_a.first.last}'
              order by column_id
            }).map do |row|              
        col = "#{row['column_name'].downcase} #{row['data_type'].downcase}"      
        if row['data_type'] =='NUMBER' and !row['data_precision'].nil?
          col << "(#{row['data_precision'].to_i}"
          col << ",#{row['data_scale'].to_i}" if !row['data_scale'].nil?
          col << ')'
        elsif row['data_type'].include?('CHAR')
          col << "(#{row['data_length'].to_i})"  
        end
        col << " default #{row['data_default']}" if !row['data_default'].nil?
        col << ' not null' if row['nullable'] == 'N'
        col
      end
      ddl << cols.join(",\n ")
      ddl << ");\n\n"
      structure << ddl
    end
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  # ------------------------------------------------------------------------
  # Private methods to support methods above
  # 
  
end # module
