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
  
  #def last_insert_id(table, sequence_name, stmt = nil)
  #end
  
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
  
  def default_sequence_name(table, primary_key=nil)
    @logger.unknown("ODBCAdapter#default_sequence_name>") if @trace
    #@logger.unknown("args=[#{table}|#{primary_key}]") if @trace
    default_pk, default_seq = pk_and_sequence_for(table)
    default_seq || "#{table}_#{primary_key || default_pk || 'id'}_seq"        
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise      
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
    sql_commands = ["ALTER TABLE #{table_name} ADD #{column_name} #{type_to_sql(type, options[:limit])}"]
    if options[:default]
      sql_commands << "ALTER TABLE #{table_name} ALTER #{column_name} SET DEFAULT '#{options[:default]}'"
    end
    if options[:null] == false
      sql_commands << "ALTER TABLE #{table_name} ALTER #{column_name} SET NOT NULL"
    end
    sql_commands.each { |cmd| execute(cmd) }
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#change_column>") if @trace
    execute "ALTER TABLE #{table_name} ALTER  #{column_name} TYPE #{type}"
    change_column_default(table_name, column_name, options[:default]) unless options[:default].nil?
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column_default(table_name, column_name, default)
    @logger.unknown("ODBCAdapter#change_column_default>") if @trace
    execute "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET DEFAULT '#{default}'"        
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def rename_column(table_name, column_name, new_column_name)
    @logger.unknown("ODBCAdapter#rename_column>") if @trace
    execute "ALTER TABLE #{table_name} RENAME COLUMN #{column_name} TO #{new_column_name}"                
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def remove_index(table_name, options = {})
    @logger.unknown("ODBCAdapter#remove_index>") if @trace
    if Hash === options
      index_name = options[:name]
    else
      index_name = "#{table_name}_#{options}_index"
    end
    execute "DROP INDEX #{index_name}"        
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  # ------------------------------------------------------------------------
  # Private methods to support methods above
  #
  private
  
  # Find a table's primary key and sequence.
  def pk_and_sequence_for(table)
    # First try looking for a sequence with a dependency on the
    # given table's primary key.
    result = select_all(<<-end_sql, 'PK and serial sequence')[0]
          SELECT attr.attname, name.nspname, seq.relname
          FROM pg_class      seq,
               pg_attribute  attr,
               pg_depend     dep,
               pg_namespace  name,
               pg_constraint cons
          WHERE seq.oid           = dep.objid
            AND seq.relnamespace  = name.oid
            AND seq.relkind       = 'S'
            AND attr.attrelid     = dep.refobjid
            AND attr.attnum       = dep.refobjsubid
            AND attr.attrelid     = cons.conrelid
            AND attr.attnum       = cons.conkey[1]
            AND cons.contype      = 'p'
            AND dep.refobjid      = '#{table}'::regclass
        end_sql
    
    if result.nil? or result.empty?
      # If that fails, try parsing the primary key's default value.
      # Support the 7.x and 8.0 nextval('foo'::text) as well as
      # the 8.1+ nextval('foo'::regclass).
      result = select_all(<<-end_sql, 'PK and custom sequence')[0]
            SELECT attr.attname, name.nspname, split_part(def.adsrc, '\\\'', 2)
            FROM pg_class       t
            JOIN pg_namespace   name ON (t.relnamespace = name.oid)
            JOIN pg_attribute   attr ON (t.oid = attrelid)
            JOIN pg_attrdef     def  ON (adrelid = attrelid AND adnum = attnum)
            JOIN pg_constraint  cons ON (conrelid = adrelid AND adnum = conkey[1])
            WHERE t.oid = '#{table}'::regclass
              AND cons.contype = 'p'
              AND def.adsrc ~* 'nextval'
          end_sql
    end
    # check for existence of . in sequence name as in public.foo_sequence.  if it does not exist, join the current namespace
    result.last['.'] ? [result.first, result.last] : [result.first, "#{result[1]}.#{result[2]}"]
  rescue
    nil
  end
  
end # module
