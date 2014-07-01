#
#  $Id: odbc_adapter.rb,v 1.8 2008/04/23 15:17:44 source Exp $
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

begin
  require_library_or_gem 'odbc' unless self.class.const_defined?(:ODBC)
  #-------------------------------------------------------------------------
  
  module ActiveRecord
    class Base  # :nodoc:
      def self.odbc_connection(config) #:nodoc:     
        config = config.symbolize_keys      
        if config.has_key?(:dsn)
          dsn = config[:dsn]
          username = config[:username] ? config[:username].to_s : nil
          password = config[:password] ? config[:password].to_s : nil
        elsif config.has_key?(:conn_str)
          connstr = config[:conn_str]
        else
          raise ActiveRecordError, "No data source name (:dsn) or connection string (:conn_str) specified."
        end

        trace = config[:trace] || false
        conv_num_lits = config[:convert_numeric_literals] || false
        emulate_bools = config[:emulate_booleans] || false

        if config.has_key?(:dsn)
	  # Connect using dsn, username, password
          conn = ODBC::connect(dsn, username, password)      
          conn_opts = { 
              :dsn => dsn, :username => username, :password => password, :schema=>config[:schema],
              :trace => trace, :conv_num_lits => conv_num_lits, 
              :emulate_booleans => emulate_bools
          }
        else  
	  # Connect using ODBC connection string 
          # - supports DSN-based or DSN-less connections
          # e.g. "DSN=virt5;UID=rails;PWD=rails"
          #      "DRIVER={OpenLink Virtuoso};HOST=carlmbp;UID=rails;PWD=rails"
          connstr_keyval_pairs = connstr.split(';')
          driver = ODBC::Driver.new
          driver.name = 'odbc'
          driver.attrs = {}
          connstr_keyval_pairs.each do |pair|
            attr = pair.split('=')
            driver.attrs[attr[0]] = attr[1] if attr.length.eql?(2)
          end
          conn = ODBC::Database.new.drvconnect(driver)
          conn_opts = {
              :conn_str => config[:conn_str], :driver => driver,
              :trace => trace, :conv_num_lits => conv_num_lits, 
              :emulate_booleans => emulate_bools
          }
        end
        conn.autocommit = true
        ConnectionAdapters::ODBCAdapter.new(conn, conn_opts, logger)
      end
    end # class Base
    
    module ConnectionAdapters # :nodoc:
      
      # This is an ODBC adapter for the ActiveRecord framework.
      #
      # The ODBC adapter requires the Ruby ODBC module (version 0.9991 or 
      # later), available from http://raa.ruby-lang.org/project/ruby-odbc
      #
      # == Status
      #
      # === 23-Apr-2008
      #
      # Adapter updated to support Rails 2.0.2 / ActiveRecord 2.0.2.
      # Added support for DSN-less connections (thanks to Ralf Vitasek).
      # Added support for SQLAnywhere (thanks to Bryan Lahartinger).
      #
      # === 27-Feb-2007
      #
      # Adapter updated to support Rails 1.2.x / ActiveRecord 1.15.x.
      # Support added for AR :decimal type and :emulate_booleans connection
      # option introduced.
      #
      # === 09-Jan-2007
      #
      # The current adapter supports Ingres r3, Informix 9.3 or later, 
      # Virtuoso (Open-Source Edition) 4.5, Oracle 10g, MySQL 5, 
      # SQL Server 2000, Sybase ASE 15, DB2 v9, Progress 9/10 (SQL-92 engine),
      # Progress 8 (SQL-89 engine) and PostgreSQL 8.2
      #
      # == Testing Environments
      #
      # The adapter has been tested in the following environments:
      # * Windows XP, Linux Fedora Core, Mac OS X
      # The iODBC Driver Manager was used on Linux and Mac OS X.
      #
      # Databases supported using OpenLink ODBC drivers:
      # * Informix, Ingres, Oracle, MySQL, SQL Server, Sybase, DB2, Progress,
      #   PostgreSQL
      # Databases supported using the database's own native ODBC driver:
      # * Virtuoso, MySQL, Informix
      #
      # === Note
      # * OpenLink ODBC drivers work with v0.998 or later of the Ruby ODBC 
      #   bridge.
      # * The native MySQL driver requires v0.9991 of the Ruby ODBC bridge.
      #
      # == Information
      #
      # More information can be found at:
      # * http://rubyforge.org/projects/odbc-rails/
      # * http://odbc-rails.openlinksw.com 
      # * http://sourceforge.net/projects/virtuoso/
      #
      # Maintainer: Carl Blakeley (mailto:cblakeley@openlinksw.co.uk)
      #
      # == Connection Options
      #
      # The following options are supported by the ODBC adapter.
      #
      # <tt>:dsn</tt>::
      #   Specifies the ODBC data source name.
      # <tt>:username</tt>::
      #   Specifies the database user.
      # <tt>:password</tt>::
      #   Specifies the database password.
      # <tt>:conn_str</tt>::
      #   Specifies an ODBC-style connection string. 
      #   e.g. 
      #        "DSN=virt5;UID=rails;PWD=rails" or
      #        "DRIVER={OpenLink Virtuoso};HOST=carlmbp;UID=rails;PWD=rails"
      #   Use either a) :dsn, :username and :password or b) :conn_str 
      #   The :conn_str option in combination with the DRIVER keyword 
      #   supports DSN-less connections.
      # <tt>:trace</tt>::
      #   If set to <tt>true</tt>, turns on simple call tracing to the log file
      #   referenced by ActiveRecord::Base.logger. If omitted, <tt>:trace</tt>
      #   defaults to <tt>false</tt>. (We also suggest setting 
      #   ActiveRecord::Base.colorize_logging = false).
      # <tt>:convert_numeric_literals</tt>::
      #   If set to <tt>true</tt>, suppresses quoting of numeric literals.
      #   If omitted, <tt>:convert_numeric_literals</tt> defaults to 
      #   <tt>false</tt>.
      # <tt>:emulate_booleans</tt>::
      #   Instructs the adapter to interpret certain numeric column types as
      #   holding boolean, rather than numeric, data. It is intended for use 
      #   with databases which do not have a native boolean data type. 
      #   If omitted, <tt>:emulate_booleans</tt> defaults to <tt>false</tt>.
      #   
      # == Usage Notes
      # === Informix
      # In order to match the formats of Ruby's Date, Time and DateTime types,
      # the following settings for Informix were used:
      # * DBDATE=Y4MD-
      # * DBTIME=%Y-%m-%d %H:%M:%S
      # To support mixed-case/quoted table names:
      # * DELIMIDENT=y
      # To allow embedded newlines in quoted strings:
      # * set ALLOW_NEWLINE=1 in the ONCONFIG configuration file.
      #
      # The adapter relies on an ODBC extension to SQLGetStmtOption implemented
      # by some ODBC drivers (SQL_LASTSERIAL=1049) to retrieve the primary key 
      # value auto-generated by an insert into a SERIAL column.
      #
      # === Ingres
      # To match the formats of Ruby's Time and DateTime types,
      # the following settings for Ingres were used:
      # * II_DATE_FORMAT=SWEDEN
      #
      # === Oracle
      # If using an OpenLink Oracle driver or agent, the 'jetfix' configuration
      # option must be enabled to obtain the correct type mappings.
      # 
      # === Sybase
      # Set the connection option :convert_numeric_literals to <tt>true</tt> to 
      # avoid errors similar to: 
      # "Implicit conversion from datatype 'VARCHAR' to 'INT' is not allowed."
      #
      # :boolean columns use the BIT SQL type, which does not allow nulls or 
      # indexes. If a DEFAULT is not specified for #create_table, the
      # column will be declared with DEFAULT 0.
      #
      # Migrations are supported, but for ALTER TABLE commands to
      # work, the database must have the database option 'select into' set to
      # 'true' with sp_dboption.
      # 
      # === DB2
      # Set the connection option :convert_numeric_literals to <tt>true</tt> to 
      # avoid errors similar to: 
      # "The data types of the operands for the operation "=" are not compatible."
      # 
      # To obtain the correct type mappings, ensure LongDataCompat is set to 1 
      # in the file db2cli.ini included in the DB2 client.
      # 
      # Migrations are supported but the following methods are not
      # implemented because of lack of support in DB2 SQL.
      # * <tt>change_column, remove_column, rename_column</tt> 
      #
      # === Progress 9/10 with SQL-92 engine
      # Connections to Progress v9 and above are assumed to be to the SQL-92 
      # engine. Migrations are supported but the following methods are not
      # implemented because of lack of support in Progress SQL.
      # * <tt>rename_table, change_column, remove_column, rename_column</tt>
      # 
      # === Progress 8 with SQL-89 engine
      # Set the connection option :convert_numeric_literals to <tt>true</tt>
      # to avoid errors similar to: 
      # "Incompatible data types in expression or assignment. (223)"
      # 
      # Migrations are supported but the following methods are not
      # implemented because of lack of support in Progress SQL.
      # * <tt>rename_table, change_column, remove_column, rename_column</tt>
      # 
      
      class ODBCAdapter < AbstractAdapter
        
        #-------------------------------------------------------------------
        # DbmsInfo holds DBMS-dependent information which cannot be derived 
        # satisfactorily through ODBC
        class DbmsInfo # :nodoc: all
          private_class_method :new
          @@dbmsInfo = nil        
          @@dbms_lookup_tbl = {
            # Uses dbmsName as key and dbmsMajorVer as a subkey.          
            :db2 => {
              :any_version => {
                :primary_key => "INTEGER GENERATED BY DEFAULT AS IDENTITY (START WITH 10000) PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "DECIMAL(1)"
              }
            },
            :informix => {
              :any_version => {
                :primary_key => "SERIAL PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                # This data adapter automatically maps ODBC::SQL_BIT to 
                # :boolean. So, the following is unnecessary if the ODBC
                # driver maps the native BOOLEAN type available in 
                # Informix 9.x to ODBC::SQL_BIT in SQLGetTypeInfo.
                :boolean_col_surrogate => "SMALLINT"
              }
            },
            :ingres => {
              :any_version => {
                :primary_key => "INTEGER PRIMARY KEY NOT NULL",
                :has_autoincrement_col => false,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "INTEGER1"
              }
            },
            :microsoftsqlserver => {
              :any_version => {
                :primary_key => "INT NOT NULL IDENTITY(1, 1) PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                # boolean_col_surrogate not necessary. 
                # SQL Server's BIT data type is mapped to ODBC::SQL_BIT/:boolean.
                :boolean_col_surrogate => nil
              },
              8 => {
                :primary_key => "INT NOT NULL IDENTITY(1, 1) PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                # boolean_col_surrogate not necessary. 
                # SQL Server's BIT data type is mapped to ODBC::SQL_BIT/:boolean.
                :boolean_col_surrogate => nil
              }
            },
            :mysql => {
              :any_version => {
                :primary_key => "INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => false,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "TINYINT"                                
              },
              5 => {
                :primary_key => "INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => false,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "TINYINT"
              }
            },
            :hdb => {
              :any_version => {
                :primary_key => "INTEGER NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => false,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "TINYINT"
              },
		},
            :oracle => {
              :any_version => {
                :primary_key => "NUMBER(10) PRIMARY KEY NOT NULL",
                :has_autoincrement_col => false,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "NUMBER(1)"
              }
            },
            :postgresql => {
              :any_version => {
                :primary_key => "SERIAL PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => false,
                :supports_count_distinct => true,
                # boolean_col_surrogate not necessary. 
                # PostgreSQL's BOOL data type is mapped to ODBC::SQL_BIT/:boolean.
                :boolean_col_surrogate => nil                
              }
            },
            :progress => {
              :any_version => {
                :primary_key => "INTEGER NOT NULL PRIMARY KEY",
                :has_autoincrement_col => false,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                # boolean_col_surrogate not necessary. 
                # Progress SQL-92's BIT data type is mapped to ODBC::SQL_BIT/:boolean.
                :boolean_col_surrogate => nil
              }
            },
            :progress89 => {
              :any_version => {
                :primary_key => "INTEGER NOT NULL UNIQUE",
                :has_autoincrement_col => false,
                :supports_migrations => true,
                :supports_schema_names => false,
                :supports_count_distinct => true,
                # boolean_col_surrogate not necessary. 
                # Progress SQL-89's LOGICAL data type is mapped to ODBC::SQL_BIT/:boolean.
                :boolean_col_surrogate => nil                
              }
            },
            :sybase => {
              :any_version => {
                :primary_key => "INT IDENTITY PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                # boolean_col_surrogate not necessary. 
                # Sybase's BIT data type is mapped to ODBC::SQL_BIT/:boolean.
                :boolean_col_surrogate => nil                                
              }
            },
            :sqlanywhere => {
              :any_version => {
                :primary_key => "INTEGER PRIMARY KEY DEFAULT AUTOINCREMENT",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "TINYINT"                                           }
            },
            :virtuoso => {
              :any_version => {
                :primary_key => "INT NOT NULL IDENTITY PRIMARY KEY",
                :has_autoincrement_col => true,
                :supports_migrations => true,
                :supports_schema_names => true,
                :supports_count_distinct => true,
                :boolean_col_surrogate => "SMALLINT"
              }
            }
          }
          
          def self.create
            @@dbmsInfo = new unless @@dbmsInfo
            @@dbmsInfo
          end
          
          def get_info(dbms_name, dbms_major_ver, info_type)
            if (val = @@dbms_lookup_tbl[dbms_name]) then
              if (val = val[dbms_major_ver] || val = val[:any_version]) then 
                val = val[info_type]        
              end
            end
            if val.nil? then
              raise ActiveRecordError, "Lookup for #{info_type} failed"
            end
            val
          end
        end # class DbmsInfo
        
        #---------------------------------------------------------------------
        # DSInfo holds SQLGetInfo responses from the data source
        class DSInfo # :nodoc: all
          attr_reader :info
          
          # Specifies the miniminum information we need about the data source
          @@baseInfo = 
            [
            ODBC::SQL_DBMS_NAME,
            ODBC::SQL_DBMS_VER,
            ODBC::SQL_IDENTIFIER_CASE,
            ODBC::SQL_QUOTED_IDENTIFIER_CASE,
            ODBC::SQL_IDENTIFIER_QUOTE_CHAR,
            ODBC::SQL_MAX_IDENTIFIER_LEN,		
            ODBC::SQL_MAX_TABLE_NAME_LEN,
            ODBC::SQL_USER_NAME,
            ODBC::SQL_DATABASE_NAME
          ]
          
          def initialize(connection)
            @connection = connection
            @info = Hash.new
            @@baseInfo.each { |i| @info[i] = nil }
            getBaseInfo(@info)
            # TODO: HACK! OpenLink's Progress ODBC driver reports 
            # SQL_IDENTIFIER_CASE as SQL_IC_MIXED, but it should be 
            # SQL_IC_UPPER. All the driver's ODBC catalog calls return 
            # identifiers in uppercase.
            @info[ODBC::SQL_IDENTIFIER_CASE] = ODBC::SQL_IC_UPPER if @info[ODBC::SQL_DBMS_NAME] =~ /progress/i
          end
          
          private
          def getBaseInfo(infoTypes)
p " ODBC::SQL_DBMS_NAME=>#{ ODBC::SQL_DBMS_NAME}"
p " ODBC::SQL_IDENTIFIER_QUOTE_CHAR=>#{ ODBC::SQL_IDENTIFIER_QUOTE_CHAR}"
p " ODBC::SQL_DATABASE_NAME=>#{ ODBC::SQL_DATABASE_NAME}"
p " ODBC::SQL_IDENTIFIER_CASE=>#{ ODBC::SQL_IDENTIFIER_QUOTE_CHAR}"
p " ODBC::SQL_QUOTED_IDENTIFIER_CASE=>#{ ODBC::SQL_QUOTED_IDENTIFIER_CASE}"
p " ODBC::SQL_MAX_IDENTIFIER_LEN=>#{ ODBC::SQL_MAX_IDENTIFIER_LEN}"
p " ODBC::SQL_MAX_TABLE_NAME_LEN=>#{ ODBC::SQL_MAX_TABLE_NAME_LEN}"
p " ODBC::SQL_USER_NAME=>#{ ODBC::SQL_USER_NAME}"
            infoTypes.each_key do |infoType|
              begin
                infoTypes[infoType] = @connection.get_info(infoType)
		p "get_info(#{infoType})=>#{infoTypes[infoType]}"
              rescue ODBC::Error
              end
            end
          end
          
        end # class DSInfo
        
        #---------------------------------------------------------------------
        
        # ODBC constants missing from Christian Werner's Ruby ODBC driver
        SQL_NO_NULLS = 0           # :nodoc:
        SQL_NULLABLE = 1           # :nodoc:
        SQL_NULLABLE_UNKNOWN = 2   # :nodoc:
        
        # dbInfo: ref to DSInfo instance
        attr_reader :dsInfo        # :nodoc:
        
        # The name of DBMS currently connected to.
        #
        # Different ODBC drivers might return different names for the same
        # DBMS; so similar names are mapped to the same symbol. 
        # _dbmsName_ is the SQL_DBMS_NAME returned by ODBC, downcased with
        # whitespace removed. e.g. <tt>informix</tt>, <tt>ingres</tt>,
        # <tt>microsoftsqlserver</tt> etc.              
        attr_reader :dbmsName
        
        # Emulate boolean columns if the database doesn't have a native BOOLEAN type.
        attr_reader :emulate_booleans
        
        # Supports lookups of DBMS-dependent information/settings which
        # cannot be derived satisfactorily through ODBC
        @@dbmsLookups = DbmsInfo.create
        
        @@trace = nil
        #--
        
        def initialize(connection, connection_options, logger = nil)
          @@trace = connection_options[:trace] && logger if !@@trace
          # Mixins in odbcext_xxx.rb included using Object#extend can't access
          # @@trace. Why?
          # (Error message "NameError: uninitialized class variable @@trace".)
          # So create an equivalent instance variable
          @trace = @@trace
          
          super(connection, logger)
          
          @logger.unknown("ODBCAdapter#initialize>") if @@trace
          
          @connection, @connection_options = connection, connection_options
          @convert_numeric_literals = connection_options[:conv_num_lits]
          @emulate_booleans = connection_options[:emulate_booleans]
          
          # Caches SQLGetInfo output
          @dsInfo = DSInfo.new(connection)
          # Caches SQLGetTypeInfo output
          @typeInfo = nil 
          # Caches mapping of Rails abstract data types to DBMS native types.
          @abstract2NativeTypeMap = nil 
          
          # Set @dbmsName and @dbmsMajorVer from SQLGetInfo output.
          # Each ODBCAdapter instance is associated with only one connection,
          # so using ODBCAdapter instance variables for DBMS name and version
          # is OK.
          
          @dbmsMajorVer = @dsInfo.info[ODBC::SQL_DBMS_VER].split('.')[0].to_i
          @dbmsName = @dsInfo.info[ODBC::SQL_DBMS_NAME].downcase.gsub(/\s/,'')
          # Different ODBC drivers might return different names for the same
          # DBMS. So map similar names to the same symbol.
          @dbmsName = dbmsNameToSym(@dbmsName, @dbmsMajorVer)
                    
          # Now we know which DBMS we're connected to, extend this ODBCAdapter 
          # instance with the appropriate DBMS specific extensions
          @odbcExtFile = "active_record/vendor/odbcext_#{@dbmsName}"
          begin     
            require "#{@odbcExtFile}"
            self.extend ODBCExt
          rescue MissingSourceFile
            puts "ODBCAdapter#initialize> Couldn't find extension #{@odbcExtFile}.rb"        
          end
        end
        
        #--
        # ABSTRACT ADAPTER OVERRIDES =======================================
        #
        # see abstract_adapter.rb
        
        # Returns the human-readable name of the adapter.
        def adapter_name
          @logger.unknown("ODBCAdapter#adapter_name>") if @@trace
          'ODBC'
        end
        
        # Does this adapter support migrations?
        def supports_migrations?
          @logger.unknown("ODBCAdapter#supports_migrations?>") if @@trace
          @@dbmsLookups.get_info(@dbmsName, @dbmsMajorVer, :supports_migrations)
        end
        
        # Does the database support COUNT(DISTINCT) queries?
        # e.g. <tt>select COUNT(DISTINCT ArtistID) from CDs</tt>
        def supports_count_distinct?
          @logger.unknown("ODBCAdapter#supports_count_distinct?>") if @@trace
          @@dbmsLookups.get_info(@dbmsName, @dbmsMajorVer, :supports_count_distinct)
        end
        
        # Should primary key values be selected from their corresponding
        # sequence before the insert statement?  If true, #next_sequence_value
        # is called before each insert to set the record's primary key.
        def prefetch_primary_key?(table_name = nil)
          @logger.unknown("ODBCAdapter#prefetch_primary_key?>") if @@trace
          # Return true for any DBMS which can't support #last_insert_id.
          # i.e. doesn't support an autoincrement column type. An 
          # implementation of #next_sequence_value must be provided for any
          # such database.
          !@@dbmsLookups.get_info(@dbmsName, @dbmsMajorVer, :has_autoincrement_col)
        end
        
        # Returns true if this connection active.
        def active?
          @logger.unknown("ODBCAdapter#active?>") if @@trace
          @connection.connected?
        end
        
        # Reconnects to the database.
        def reconnect!
          @logger.unknown("ODBCAdapter#reconnect!>") if @@trace
          @connection.disconnect if @connection.connected?
          if @connection_options.has_key?(:dsn)
            @connection = ODBC::connect(@connection_options[:dsn], 
                                        @connection_options[:username],
                                        @connection_options[:password])
          else
            @connection = ODBC::Database.new.drvconnect(@connection_options[:driver])
          end
          # There's no need to refresh the data source info in @dsInfo because
          # we're reconnecting to the same data source.
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Disconnects from the database.
        def disconnect!
          @logger.unknown("ODBCAdapter#disconnect!>") if @@trace
          @connection.disconnect if @connection.connected?
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        #--
        # QUOTING OVERRIDES ================================================
        #
        # see: abstract/quoting.rb
        
        # Quotes the column value
        #--
        # to help prevent {SQL injection attacks}[http://en.wikipedia.org/wiki/SQL_injection].
        #++
        def quote(value, column = nil)
          @logger.unknown("ODBCAdapter#quote>") if @@trace
          @logger.unknown("args=[#{value}]") if @@trace
          case value
          when String, ActiveSupport::Multibyte::Chars          
            value = value.to_s
            if column && column.type == :binary && self.respond_to?(:string_to_binary)
              "'#{string_to_binary(value)}'"
            elsif (column && [:integer, :float].include?(column.type))
              value = column.type == :integer ? value.to_i : value.to_f
              value.to_s            
            elsif (column.nil? && @convert_numeric_literals && 
                  (value =~ /^[-+]?[0-9]+[.]?[0-9]*([eE][-+]?[0-9]+)?$/))
              value
            else
              "'#{quote_string(value)}'" # ' (for ruby-mode)
            end
          when NilClass then "NULL"
          when TrueClass then (column && column.type == :integer ?
              '1' : quoted_true)
          when FalseClass then (column && column.type == :integer ? 
              '0' : quoted_false)
          when Float, Fixnum, Bignum then value.to_s          
          else
            if value.acts_like?(:date) || value.acts_like?(:time)
              quoted_date(value)
            else
              super
            end
          end
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Quotes a string, escaping any ' (single quote) and \ (backslash)
        # characters.
        def quote_string(string)
          @logger.unknown("ODBCAdapter#quote_string>") if @@trace
          @logger.unknown("args=[#{string}]") if @@trace        
          string.gsub(/\'/, "''")
        end
        
        # Returns a quoted form of the column name.
        def quote_column_name(name)
          @logger.unknown("ODBCAdapter#quote_column_name>") if @@trace
          @logger.unknown("args=[#{name}]") if @@trace        
          name = name.to_s if name.class == Symbol                
          idQuoteChar = @dsInfo.info[ODBC::SQL_IDENTIFIER_QUOTE_CHAR]
p "ODBC::SQL_IDENTIFIER_QUOTE_CHAR=#{idQuoteChar}"
          return name if !idQuoteChar || ((idQuoteChar = idQuoteChar.strip).length == 0)
          idQuoteChar = idQuoteChar[0]
          
p "1ODBC::SQL_IDENTIFIER_QUOTE_CHAR=#{idQuoteChar}"
          # Avoid quoting any already quoted name
          return name if name[0] == idQuoteChar && name[-1] == idQuoteChar
          
p "11DBC::SQL_IDENTIFIER_CASE=#{@dsInfo.info[ODBC::SQL_IDENTIFIER_CASE]}, ODBC::SQL_IC_UPPER=>#{ODBC::SQL_IC_UPPER}"
          # If DBMS's SQL_IDENTIFIER_CASE = SQL_IC_UPPER, only quote mixed 
          # case names.
          # See #dbmsIdentCase for the identifier case conventions used by this
          # adapter.
          if @dsInfo.info[ODBC::SQL_IDENTIFIER_CASE] == ODBC::SQL_IC_UPPER
            return name unless (name =~ /([A-Z]+[a-z])|([a-z]+[A-Z])/)
          end
          
p "12DBC::SQL_IDENTIFIER_QUOTE_CHAR=#{idQuoteChar}"
          idQuoteChar.chr + name + idQuoteChar.chr
        end
        
        def quote_table_name(name)
          @logger.unknown("ODBCAdapter#quote_table_name>") if @trace
          @logger.unknown("args=[#{name}]") if @trace        
          quote_column_name(name)
        end

        def quoted_true
          @logger.unknown("ODBCAdapter#quoted_true>") if @@trace
          '1'
        end
        
        def quoted_false
          @logger.unknown("ODBCAdapter#quoted_false>") if @@trace
          '0'
        end
        
        def quoted_date(value)
          @logger.unknown("ODBCAdapter#quoted_date>") if @@trace
          @logger.unknown("args=[#{value}]") if @@trace     

          # abstract_adapter's #quoted_date uses value.to_s(:db), but this
          # doesn't differentiate between pure dates (Date) and date/time
          # composites (Time and DateTime).
          # :db format string defaults to '%Y-%m-%d %H:%M:%S' and is defined
          # in ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS
          
          # Ideally, we'd return an ODBC date or timestamp literal escape 
          # sequence, but not all ODBC drivers support them.
          if value.acts_like?(:time) # Time, DateTime
            #%Q!{ts #{value.strftime("%Y-%m-%d %H:%M:%S")}}!
            %Q!'#{value.strftime("%Y-%m-%d %H:%M:%S")}'!
          else # Date
            #%Q!{d #{value.strftime("%Y-%m-%d")}}!
            %Q!'#{value.strftime("%Y-%m-%d")}'!
          end
        end
        
        #--
        # DATABASE STATEMENTS OVERRIDES ====================================
        #
        # see: abstract/database_statements.rb
        
        # Begins a transaction (and turns off auto-committing).
        def begin_db_transaction
          @logger.unknown("ODBCAdapter#begin_db_transaction>") if @@trace
          @connection.autocommit = false
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Commits the transaction (and turns on auto-committing).
        def commit_db_transaction
          @logger.unknown("ODBCAdapter#commit_db_transaction>") if @@trace
          @connection.commit
          # ODBC chains transactions. Turn autocommit on after commit to
          # allow explicit transaction initiation.
          @connection.autocommit = true
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Rolls back the transaction (and turns on auto-committing). 
        def rollback_db_transaction
          @logger.unknown("ODBCAdapter#rollback_db_transaction>") if @@trace
          @connection.rollback
          # ODBC chains transactions. Turn autocommit on after rollback to
          # allow explicit transaction initiation.
          @connection.autocommit = true
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Appends +LIMIT+ and/or +OFFSET+ options to a SQL statement.
        # See DatabaseStatements#add_limit_offset!
        #--
        # Base class accepts only +LIMIT+ *AND* +OFFSET+      
        def add_limit_offset!(sql, options)
          @logger.unknown("ODBCAdapter#add_limit_offset!>") if @@trace
          @logger.unknown("args=[#{sql}]") if @@trace        
          if limit = options[:limit] then sql << " LIMIT #{limit}" end
          if offset = options[:offset] then sql << " OFFSET #{offset}" end
        end
        
        # Returns an array of record hashes with the column names as keys and
        # column values as values.
        def select_all(sql, name = nil)
          @logger.unknown("ODBCAdapter#select_all>") if @@trace
          @logger.unknown("args=[#{sql}|#{name}]") if @@trace
          retVal = []
          hResult = select(sql, name)
          rRows = hResult[:rows]
          rColDescs = hResult[:column_descriptors]
          
          # Convert rows from arrays to hashes					
          if rRows
            rRows.each do |row|
              h = Hash.new
              (0...row.length).each do |iCol|
                h[activeRecIdentCase(rColDescs[iCol].name)] = 
                  convertOdbcValToGenericVal(row[iCol])
              end
              retVal << h
            end
          end
          
          retVal
        end
        
        # Returns a record hash with the column names as keys and column values
        # as values.
        def select_one(sql, name = nil)
          @logger.unknown("ODBCAdapter#select_one>") if @@trace
          @logger.unknown("args=[#{sql}|#{name}]") if @@trace
          retVal = nil
          scrollableCursor = false
          offset = 0
          qry = sql.dup
          
          # Strip OFFSET and LIMIT from query if present, since ODBC doesn't
          # support them in a generic form.
          #
          # TODO: Translate any OFFSET/LIMIT option to native SQL if DBMS supports it.
          # This will perform much better than simulating them.
          if qry =~ /(\bLIMIT\s+)(\d+)/i then
            # Check for 'LIMIT 0'	otherwise ignore LIMIT				
            if $2.to_i == 0 then return retVal end
          end
          
          if qry =~ /(\bOFFSET\s+)(\d+)/i then offset = $2.to_i end
          qry.gsub!(/(\bLIMIT\s+\d+|\bOFFSET\s+\d+)/i, '')
          
          # It's been assumed that it's quicker to support an offset
          # restriction using a forward-only cursor. A static cursor will 
          # presumably take a snapshot of the whole result set, whereas when 
          # using a forward-only cursor we only fetch the first offset+1 
          # rows.
=begin        
        if offset > 0 then
          scrollableCursor = true
          begin
            # ODBCStatement::fetch_first requires a scrollable cursor
            @connection.cursortype = ODBC::SQL_CURSOR_STATIC
          rescue
            # Assume ODBC driver doesn't support scrollable cursors
            @connection.cursortype = ODBC::SQL_CURSOR_FORWARD_ONLY
            scrollableCursor = false
          end
        end
=end        
          # Execute the query
          begin
            stmt = @connection.run(qry)
          rescue Exception => e
            @logger.unknown("exception=#{e}") if @@trace
            stmt.drop unless stmt.nil?
            raise StatementInvalid, e.message
          end
          
          # Get one row, handling any offset stipulated
          rColDescs = stmt.columns(true)
          if scrollableCursor then
            # scrollableCursor == true => offset > 0
            stmt.fetch_scroll(ODBC::SQL_FETCH_ABSOLUTE, offset)
            row = stmt.fetch
          else
            row = nil
            rRows = stmt.fetch_many(offset + 1)
            if rRows && rRows.length > offset then 
              row = rRows[offset]
            end
          end
          
          # Convert row from array to hash
          if row then
            retVal = h = Hash.new
            (0...row.length).each do |iCol|
              h[activeRecIdentCase(rColDescs[iCol].name)] = 
                convertOdbcValToGenericVal(row[iCol])
            end
          end
          
          stmt.drop
          retVal
        end
        
        # Executes the SQL statement in the context of this connection.
        # Returns the number of rows affected.
        def execute(sql, name = nil)
          @logger.unknown("ODBCAdapter#execute>") if @@trace
          @logger.unknown("args=[#{sql}|#{name}]") if @@trace
          if sql =~ /^\s*INSERT/i && 
              [:microsoftsqlserver, :virtuoso, :sybase].include?(@dbmsName)
            # Guard against IDENTITY insert problems caused by explicit inserts
            # into autoincrementing id column.
p "execute sql:#{sql}"
            insert(sql, name)
          else
p "execute sql:#{sql}"
            begin
              @connection.do(sql)
            rescue Exception => e
              @logger.unknown("exception=#{e}") if @@trace
              raise StatementInvalid, e.message
            end
          end
        end
        
        # Returns the ID of the last inserted row.
        def insert(sql, name = nil, pk = nil, id_value = nil, 
            sequence_name = nil)
          @logger.unknown("ODBCAdapter#insert>") if @@trace
          @logger.unknown("args=[#{sql}|#{name}|#{pk}|#{id_value}|#{sequence_name}]") if @@trace
          insert_sql(sql, name, pk, id_value, sequence_name)
        end
        
        # Returns the default sequence name for a table.
        # Used for databases which don't support an autoincrementing column 
        # type, but do support sequences.
        def default_sequence_name(table, column)
          @logger.unknown("ODBCAdapter#default_sequence_name>") if @@trace
          @logger.unknown("args=[#{table}|#{column}]") if @@trace
          "#{table}_seq"
        end
        
        # Set the sequence to the max value of the table�s column.
        def reset_sequence!(table, column, sequence = nil)
          @logger.unknown("ODBCAdapter#reset_sequence!>") if @@trace
          @logger.unknown("args=[#{table}|#{column}|#{sequence}]") if @@trace
          super(table, column, sequence)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        #--
        # SCHEMA STATEMENTS OVERRIDES ======================================
        #
        # see: abstract/schema_statements.rb
        
        def create_database(name)
          @logger.unknown("ODBCAdapter#create_database>") if @trace
          @logger.unknown("args=[#{name}]") if @trace            
          # raise NotImplementedError, "create_database is not implemented"
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @trace
          raise
        end
        
        def drop_database(name)
          @logger.unknown("ODBCAdapter#drop_database>") if @trace
          @logger.unknown("args=[#{name}]") if @trace            
          # raise NotImplementedError, "drop_database is not implemented"
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @trace
          raise
        end
        
        #--
        # Required by db:test:purge Rake task (see databases.rake)
        def recreate_database(name, fail_quietly = false)
          @logger.unknown("ODBCAdapter#recreate_database>") if @@trace
          @logger.unknown("args=[#{name}|#{fail_quietly}]") if @@trace
          begin
            drop_database(name)
            create_database(name)
          rescue Exception => e
            raise unless fail_quietly
          end
        end
        
        def current_database
          @dsInfo.info[ODBC::SQL_DATABASE_NAME].strip
        end

        # The maximum length a table alias can be.
        def table_alias_length
          maxIdentLen = @dsInfo.info[ODBC::SQL_MAX_IDENTIFIER_LEN]
          maxTblNameLen = @dsInfo.info[ODBC::SQL_MAX_TABLE_NAME_LEN]
          maxTblNameLen < maxIdentLen ? maxTblNameLen : maxIdentLen
        end
        
        # Returns an array of table names, for database tables visible on the
        # current connection.
        def tables(name = nil)
p "show tables"
          @logger.unknown("ODBCAdapter#tables>") if @@trace
          @logger.unknown("args=[#{name}]") if @@trace
          tblNames = []
          # TODO: ODBC::Connection#tables cannot filter on schema name
          # Modify Werner's Ruby ODBC driver to allow this
          currentUser = @dsInfo.info[ODBC::SQL_USER_NAME]
          stmt = @connection.tables
          resultSet = stmt.fetch_all || []
          resultSet.each do |row|
            schemaName = row[1]
            tblName = row[2]
            tblType = row[3]
            next if respond_to?("table_filter") && table_filter(schemaName, tblName, tblType)
            if @@dbmsLookups.get_info(@dbmsName, @dbmsMajorVer, :supports_schema_names)
#	p "schemaName=#{schemaName}, currentUser=#{currentUser}"
              tblNames << activeRecIdentCase(tblName) if schemaName.casecmp(currentUser) == 0
            else
              tblNames << activeRecIdentCase(tblName)
            end
          end
          stmt.drop
          tblNames
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Returns an array of Column objects for the table specified by +table_name+.
        def columns(table_name, name = nil)
          @logger.unknown("ODBCAdapter#columns>") if @@trace
          @logger.unknown("args=[#{table_name}|#{name}]") if @@trace
          
          table_name = table_name.to_s if table_name.class == Symbol
          
          getDbTypeInfo
          begin
            booleanColSurrogate = @emulate_booleans ? @@dbmsLookups.get_info(@dbmsName, @dbmsMajorVer, :boolean_col_surrogate) : nil
          rescue Exception
            # No boolean column surrogate defined for target database in lookup table
            booleanColSurrogate = nil
            @emulate_booleans = false
          end  
          cols = []
          stmt = @connection.columns(dbmsIdentCase(table_name))
          resultSet = stmt.fetch_all || []
          resultSet.each do |col|
            colName = col[3] # SQLColumns: COLUMN_NAME
            colDefault = col[12] # SQLColumns: COLUMN_DEF
            colSqlType = col[4] # SQLColumns: DATA_TYPE
            colNativeType = col[5] # SQLColumns: TYPE_NAME
            colLimit = col[6] # SQLColumns: COLUMN_SIZE
            colScale = col[8] # SQLColumns: DECIMAL_DIGITS
            
            odbcIsNullable = col[17] # SQLColumns: IS_NULLABLE
            odbcNullable = col[10] # SQLColumns: NULLABLE
            # isNotNullable == true  => *definitely not* nullable
            #               == false => *may* be nullable
            isNotNullable = (odbcIsNullable.match('NO') != nil)
            # Assume column is nullable if odbcNullable == SQL_NULLABLE_UNKNOWN
            colNullable = !(isNotNullable || odbcNullable == SQL_NO_NULLS)
            
            # HACK!
            # MySQL native ODBC driver doesn't report nullability accurately.
            # So force nullability of 'id' columns
            colNullable = false if colName == 'id'
            
            # SQL Server ODBC drivers may wrap default value in parentheses
            if colDefault =~ /^\('(.*)'\)$/ # SQL Server character default
              colDefault = $1
            elsif colDefault =~ /^\((.*)\)$/ # SQL Server numeric default
              colDefault = $1
              # ODBC drivers should return string column defaults in quotes
              # - strip off the quotes
              # - Oracle may include a trailing space.
              # - PostgreSQL may return '<default>::character varying'
            elsif colDefault =~ /^'(.*)'([ :].*)*$/
              colDefault = $1
              #TODO: HACKS for Progress
            elsif @dbmsName == :progress || @dbmsName == :progress89
              if colDefault =~ /^\?$/
                colDefault = nil
              elsif colSqlType == ODBC::SQL_BIT
                if ["yes", "no"].include?(colDefault)
                  colDefault = colDefault == "yes" ? 1 : 0
                end
              end
            end
            cols << ODBCColumn.new(activeRecIdentCase(colName), table_name, 
              colDefault, colSqlType, colNativeType, colNullable, colLimit, 
              colScale, @odbcExtFile+"_col", booleanColSurrogate, native_database_types())
          end
          stmt.drop
          cols
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Returns an array of indexes for the given table.
        def indexes(table_name, name = nil)
          @logger.unknown("ODBCAdapter#indexes>") if @@trace
          @logger.unknown("args=[#{table_name}|#{name}]") if @@trace
          
          indexes = []
          indexCols = indexName = isUnique = nil
          
          stmt = @connection.indexes(dbmsIdentCase(table_name.to_s))
          rs = stmt.fetch_all || []
          rs.each_index do |iRow|
            row = rs[iRow]
            
            # Skip table statistics
            next if row[6] == 0 # SQLStatistics: TYPE
            
            if (row[7] == 1) # SQLStatistics: ORDINAL_POSITION
              # Start of column descriptor block for next index
              indexCols = Array.new
              isUnique = (row[3] == 0) # SQLStatistics: NON_UNIQUE
              indexName = String.new(row[5]) # SQLStatistics: INDEX_NAME
            end

            indexCols << activeRecIdentCase(row[8]) # SQLStatistics: COLUMN_NAME
            
            lastRow = (iRow == rs.length - 1)
            if lastRow
              lastColOfIndex = true
            else
              nextRow = rs[iRow + 1]
              lastColOfIndex = (nextRow[6] == 0 || nextRow[7] == 1)
            end

            if lastColOfIndex
              indexes << IndexDefinition.new(table_name, 
                activeRecIdentCase(indexName), isUnique, indexCols)
            end
          end
          indexes
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        ensure
          stmt.drop unless stmt.nil?
        end
        
        # Returns a Hash of mappings from Rails' abstract data types to the 
        # native database types.  
        # See TableDefinition#column for details of the abstract data types.
        def native_database_types
          @logger.unknown("ODBCAdapter#native_database_types>") if @@trace
          
          return {}.merge(@abstract2NativeTypeMap) unless @abstract2NativeTypeMap.nil?
          
          @abstract2NativeTypeMap = 
            {
            :primary_key => nil,
            :string      => nil,
            :text        => nil,
            :integer     => nil,
            :decimal     => nil,
            :float       => nil,
            :datetime    => nil,
            :timestamp   => nil,
            :time        => nil,
            :date        => nil,
            :binary      => nil,
            :boolean     => nil
          }
          
          getDbTypeInfo
          
          # hAbs2Sql = Hash of ActiveRecord abstract types to ODBC SQL types
          hAbs2Sql = genericTypeToOdbcSqlTypesMap
          
          # hSql2Native = Hash of ODBC native data type descriptors from
          #              SQLGetTypeInfo keyed on ODBC SQL type.
          # The hash value is an array of all rows in the SQLGetTypeInfo result
          # set for which DATA_TYPE matches the key.
          hSql2Native = Hash.new
          @typeInfo.each do |row|
            sqlType = row[1] # SQLGetTypeInfo: DATA_TYPE
            if (rNativeTypeDescs = hSql2Native[sqlType]) == nil
              hSql2Native[sqlType] = rNativeTypeDescs = Array.new()
            end
            rNativeTypeDescs << row
          end
          
          # For a particular abstract type, check if the DBMS supports one of
          # the corresponding ODBC SQL types then, if so, find the native DBMS
          # types corresponding to this ODBC SQL type and select the most
          # suitable. (For each SQL type, SQLGetTypeInfo should return the
          # closest match first).
          @abstract2NativeTypeMap.each_key do |abstractType|
            rCandidateSqlTypes = hAbs2Sql[abstractType]
            isSupported = false
            rCandidateSqlTypes.each do |sqlType|
              if (rNativeTypeDescs = hSql2Native[sqlType])
                @abstract2NativeTypeMap[abstractType] = 
                  nativeTypeMapping(abstractType, rNativeTypeDescs)
                isSupported = true
                break
              end
            end
            @logger.unknown("WARNING: No suitable DBMS type for abstract type #{abstractType.to_s}") if !isSupported && @@trace
          end

          begin                    
            booleanColSurrogate = @emulate_booleans ? @@dbmsLookups.get_info(@dbmsName, @dbmsMajorVer, :boolean_col_surrogate) : nil
          rescue Exception
            # No boolean column surrogate defined for target database in lookup table
            booleanColSurrogate = nil
            @emulate_booleans = false              
          end
          @abstract2NativeTypeMap[:boolean] = {:name => booleanColSurrogate} if booleanColSurrogate
          
          {}.merge(@abstract2NativeTypeMap)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Creates a new table. See SchemaStatements#create_table.
        def create_table(name, options = {})
          @logger.unknown("ODBCAdapter#create_table>") if @@trace
          @logger.unknown("args=[#{name}]") if @@trace
	p "==>create_table name:#{name}, options:#{options.inspect}"
          #super(name, options)
	#copy from super
	table_name = name
        table_definition = TableDefinition.new(self)
        table_definition.primary_key(options[:primary_key] || Base.get_primary_key(table_name.to_s.singularize)) unless options[:id] == false

        yield table_definition

        if options[:force] && table_exists?(table_name)
          drop_table(table_name, options)
        end

        create_sql = "CREATE#{' TEMPORARY' if options[:temporary]} COLUMN TABLE "
        create_sql << "#{quote_table_name(table_name)} ("
        create_sql << table_definition.to_sql
        create_sql << ") #{options[:options]}"
p "===>create sql:"+create_sql
        execute create_sql
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
	p "!!!Exception:#{e.inspect}:\n#{e.backtrace[0..9].join("\n")}"
          raise ActiveRecordError, e.message
        end
        
        # Renames a table.
        def rename_table(name, new_name)
          @logger.unknown("ODBCAdapter#rename_table>") if @@trace
          @logger.unknown("args=[#{name}|#{new_name}]") if @@trace
          # Base class raises NotImplementedError
          super(name, new_name)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Drops a table from the database.
        def drop_table(name, options = {})
          @logger.unknown("ODBCAdapter#drop_table>") if @@trace
          @logger.unknown("args=[#{name}]") if @@trace
          super(name, options)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Adds a new column to the named table.
        # See TableDefinition#column for details of the options you can use.      
        def add_column(table_name, column_name, type, options = {})
          @logger.unknown("ODBCAdapter#add_column>") if @@trace
          @logger.unknown("args=[#{table_name}|#{column_name}|#{type}]") if @@trace
          super(table_name, column_name, type, options)				
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Removes the column from the table definition.
        def remove_column(table_name, column_name)
          @logger.unknown("ODBCAdapter#remove_column>") if @@trace
          @logger.unknown("args=[#{table_name}|#{column_name}]") if @@trace
          super(table_name, column_name)								
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Changes the column's definition according to the new options. 
        # See TableDefinition#column for details of the options you can use.
        def change_column(table_name, column_name, type, options = {})
          @logger.unknown("ODBCAdapter#change_column>") if @@trace
          @logger.unknown("args=[#{table_name}|#{column_name}|#{type}]") if @@trace
          # Base class raises NotImplementedError
          super(table_name, column_name, type, options)            							
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Sets a new default value for a column.
        def change_column_default(table_name, column_name, default)
          @logger.unknown("ODBCAdapter#change_column_default>") if @@trace
          @logger.unknown("args=[#{table_name}|#{column_name}]") if @@trace
          super(table_name, column_name, default)												
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        def rename_column(table_name, column_name, new_column_name)
          @logger.unknown("ODBCAdapter#rename_column>") if @@trace
          @logger.unknown("args=[#{table_name}|#{column_name}|#{new_column_name}]") if @@trace
          # Base class raises NotImplementedError
          super(table_name, column_name, new_column_name)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        def remove_index(table_name, options = {})
          @logger.unknown("ODBCAdapter#remove_index>") if @@trace
          @logger.unknown("args=[#{table_name}]") if @@trace
          super(table_name, options)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Not exercised by ActiveRecord test suite
        def structure_dump # :nodoc:
          @logger.unknown("ODBCAdapter#structure_dump>") if @@trace
          raise NotImplementedError, "structure_dump is not implemented"
        end
        
        #--
        # WRAPPER METHODS FOR TRACING ======================================
        
        #--
        # ------------------------------------------------------------------
        # see: abstract/database_statements.rb
        
        # Returns a single value from a record
        #--
        # No need to implement beyond a tracing wrapper
        def select_value(sql, name = nil)
          @logger.unknown("ODBCAdapter#select_value>") if @@trace
          @logger.unknown("args=[#{sql}|#{name}]") if @@trace
          super(sql, name)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise StatementInvalid, e.message
        end
        
        # Returns an array of the values of the first column in a select.
        def select_values(sql, name = nil)
p "select_all sql=>#{sql}, name=>#{name}"
          @logger.unknown("ODBCAdapter#select_values>") if @@trace
          @logger.unknown("args=[#{sql}|#{name}]") if @@trace        
          result = select_all(sql, name)
          result.map{ |v| v.values.first }
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise StatementInvalid, e.message
        end
        
        # Returns an array of arrays containing the field values.
        # Order is the same as that returned by #columns.
        def select_rows(sql, name = nil)
          @logger.unknown("ODBCAdapter#select_rows>") if @@trace
          @logger.unknown("args=[#{sql}|#{name}]") if @@trace
          hResult = select(sql, name)
          hResult[:rows]
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise StatementInvalid, e.message
        end

        # Wrap a block in a transaction. Returns result of block.
        #--
        # No need to implement beyond a tracing wrapper
        def transaction(start_db_transaction = true)
          @logger.unknown("ODBCAdapter#transaction>") if @@trace
          super(start_db_transaction)
        rescue Exception => e
          @logger.unknown("#{e.class}: #{e}") if @@trace
          raise
        end
        
        # Alias for #add_limit_offset!
        #--
        # No need to implement beyond a tracing wrapper
        def add_limit!(sql, options)
          @logger.unknown("ODBCAdapter#add_limit!>") if @@trace
          @logger.unknown("args=[#{sql}]") if @@trace
          super(sql, options)
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # Returns the last auto-generated ID from the affected table.
        def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil) # :nodoc:  
          # id_value ::= pre-assigned id
          retry_count = 0
          begin
p "===>pre_insert_sql:"+sql
            pre_insert(sql, name, pk, id_value, sequence_name) if respond_to?("pre_insert")
	p "===>insert_sql:"+sql
            stmt = @connection.run(sql)
            table = sql.split(" ", 4)[2]
            res = id_value || last_insert_id(table, sequence_name || 
                default_sequence_name(table, pk), stmt)
          rescue Exception => e
            @logger.unknown("exception=#{e}") if @@trace
            if @dbmsName == :virtuoso  && id_value.nil? && e.message =~ /sr197/i
              # Error: Non unique primary key
              # If id column is an autoincrementing IDENTITY column and there
              # have been prior inserts using explicit id's, the sequence 
              # associated with the id column could lag behind the id values
              # inserted explicitly. In the course of subsequent inserts, if
              # an explicit id isn't given, the autogenerated id may collide
              # with a previously explicitly inserted value.
              unless stmt.nil?
                stmt.drop; stmt = nil
              end
              table_name = e.message =~/Non unique primary key on (\w+\.\w+\.\w+)/i ? $1 : nil
              if table_name && retry_count == 0
                retry_count += 1
                # Set next sequence value to be greater than current max. pk value
                set_sequence(table_name, pk)
                retry
              end
            end
            raise StatementInvalid, e.message
          ensure
            post_insert(sql, name, pk, id_value, sequence_name) if respond_to?("post_insert")
            stmt.drop unless stmt.nil?
          end
          res
        end

        #--
        # ------------------------------------------------------------------
        # see: abstract/schema_statements.rb
        
        # Adds a new index to the table.
        # See SchemaStatements#add_index.
        #--
        # No need to implement beyond a tracing wrapper
        def add_index(table_name, column_name, options = {})
          @logger.unknown("ODBCAdapter#add_index>") if @@trace
          @logger.unknown("args=[#{table_name}|#{column_name}]") if @@trace
          super(table_name, column_name, options)																
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        #--
        # If the index is not explicitly named using the :name option, 
        # there's a risk the generated index name could exceed the maximum
        # length supported by the database. 
        # i.e. dsInfo.info[ODBC::SQL_MAX_IDENTIFIER_LEN]
        def index_name(table_name, options) # :nodoc:
          @logger.unknown("ODBCAdapter#index_name>") if @@trace
          @logger.unknown("args=[#{table_name}]") if @@trace
          super
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        def type_to_sql(type, limit = nil, precision = nil, scale = nil) # :nodoc:
          @logger.unknown("ODBCAdapter#type_to_sql>") if @@trace
          @logger.unknown("args=[#{type}|#{limit}|#{precision}|#{scale}]") if @@trace
          if native = native_database_types[type]
            column_type_sql = String.new(native.is_a?(Hash) ? native[:name] : native)
            if type == :decimal # ignore limit, use precision and scale
              precision ||= native[:precision]
              scale ||= native[:scale]
              if precision
                if scale
                  column_type_sql << "(#{precision},#{scale})"
                else
                  column_type_sql << "(#{precision})"
                end
              else
                raise ArgumentError, "Error adding decimal column: precision cannot be empty if scale if specified" if scale
              end
              column_type_sql          
            else
              # if there's no limit in the type definition, assume that the type 
              # doesn't support a length qualifier
              column_type_sql << "(#{limit || native[:limit]})" if native[:limit]
              column_type_sql        																											
            end
          else
            @logger.unknown("Warning! Type #{type} not present in native_database_types") if @@trace
            column_type_sql = type
          end
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # No need to implement beyond tracing wrapper
        def add_column_options!(sql, options) # :nodoc:
          @logger.unknown("ODBCAdapter#add_column_options!>") if @@trace
          @logger.unknown("args=[#{sql}]") if @@trace
          super(sql, options)																												
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise StatementInvalid, e.message
        end
        
        # No need to implement beyond tracing wrapper
        def dump_schema_information # :nodoc:
          @logger.unknown("ODBCAdapter#dump_schema_information>") if @@trace
          super																												
        rescue Exception => e
          @logger.unknown("exception=#{e}") if @@trace
          raise ActiveRecordError, e.message
        end
        
        # ==================================================================

        private
        
        #--
        # Executes a SELECT statement, returning a hash containing the 
        # result set rows (key :rows) and the result set column descriptors
        # (key :column_descriptors) as arrays.
        def select(sql, name) # :nodoc:
          scrollableCursor = false
          limit = 0
          offset = 0
          qry = sql.dup
          
          # Strip OFFSET and LIMIT from query if present, since ODBC doesn't
          # support them in a generic form.
          #
          # TODO: Translate any OFFSET/LIMIT option to native SQL if DBMS supports it.
          # This will perform much better than simulating them.
          if qry =~ /(\bLIMIT\s+)(\d+)/i then
            if (limit = $2.to_i) == 0 then return Array.new end
          end
          
          if qry =~ /(\bOFFSET\s+)(\d+)/i then offset = $2.to_i end
          qry.gsub!(/(\bLIMIT\s+\d+|\bOFFSET\s+\d+)/i, '')
          
          # It's been assumed that it's quicker to support an offset and/or
          # limit restriction using a forward-only cursor. A static cursor will 
          # presumably take a snapshot of the whole result set, whereas when 
          # using a forward-only cursor we only fetch the first offset+limit 
          # rows.
=begin        
        if offset > 0 then
          scrollableCursor = true
          begin
            # ODBCStatement::fetch_first requires a scrollable cursor
            @connection.cursortype = ODBC::SQL_CURSOR_STATIC
          rescue
            # Assume ODBC driver doesn't support scrollable cursors
            @connection.cursortype = ODBC::SQL_CURSOR_FORWARD_ONLY
            scrollableCursor = false
          end
        end
=end
          
          # Execute the query
          begin
            stmt = @connection.run(qry)
          rescue Exception => e
            stmt.drop unless stmt.nil?
            @logger.unknown("exception=#{e}") if @@trace && name != :force_error
            raise StatementInvalid, e.message
          end
          
          rColDescs = stmt.columns(true)
          
          # Get the rows, handling any offset and/or limit stipulated
          if scrollableCursor then
            rRows = nil
            # scrollableCursor == true => offset > 0
            if stmt.fetch_scroll(ODBC::SQL_FETCH_ABSOLUTE, offset)
              rRows = limit > 0 ? stmt.fetch_many(limit) : stmt.fetch_all
            end
          else
            rRows = limit > 0 ? stmt.fetch_many(offset + limit) : stmt.fetch_all
            # Enforce OFFSET
            if offset > 0 then 
              if rRows && rRows.length > offset then
                rRows.slice!(0, offset)
              else
                rRows = nil
              end
            end
            # Enforce LIMIT
            if limit > 0 && rRows && rRows.length > limit then
              rRows.slice!(limit..(rRows.length-1))
            end
          end
          
          stmt.drop
          {:rows => rRows, :column_descriptors => rColDescs}       
        end
        
        # Maps a DBMS name to a symbol.
        #
        # Different ODBC drivers might return different names for the same
        # DBMS. So #dbmsNameToSym maps similar names to the same symbol.
        #
        # If adding an odbcext_xxx extension module for a particular DBMS,
        # you should define a symbol here for the target DBMS.
        #
        # dbmsName is the SQL_DBMS_NAME returned by ODBC, downcased with
        # whitespace removed.
        def dbmsNameToSym(dbmsName, dbmsVer)
          if dbmsName =~ /db2/i
            symbl = :db2
          elsif dbmsName =~ /informix/i
            symbl = :informix
          elsif dbmsName =~ /ingres/i
            symbl = :ingres
          elsif dbmsName =~ /my.*sql/i
            symbl = :mysql
          elsif dbmsName =~ /oracle/i
            symbl = :oracle 
          elsif dbmsName =~ /postgres/i
            symbl = :postgresql
          elsif dbmsName =~ /progress/i
            # ODBC connections to Progress >= v9 are assumed to be to
            # the SQL-92 engine. Connections to Progress <= v8 are
            # assumed to be to the SQL-89 engine.
            symbl = dbmsVer <= 8 ? :progress89 : :progress
          elsif dbmsName =~ /sql.*server/i
            symbl = :microsoftsqlserver
          elsif dbmsName =~ /sybase/i
            symbl = :sybase
          elsif dbmsName =~ /virtuoso/i
            symbl = :virtuoso 
          elsif dbmsName =~ /SQLAnywhere/i
            symbl = :sqlanywhere
	elsif dbmsName =~ /hdb/i
		symbl = :hdb
          else
            raise ActiveRecord::ActiveRecordError, "ODBCAdapter: Unsupported database (#{dbmsName})"
          end
          symbl
        end
        
        # Returns a Hash of mappings for each ActiveRecord abstract data type to 
        # one or more ODBC SQL types
        #
        # Where more than one ODBC SQL type is associated with an abstract type,
        # the SQL types in the value array are in order of preference.
        def genericTypeToOdbcSqlTypesMap
          map = 
            {
            :primary_key => [ODBC::SQL_INTEGER, ODBC::SQL_SMALLINT],
            :string => [ODBC::SQL_VARCHAR],
            :text => [ODBC::SQL_LONGVARCHAR, ODBC::SQL_VARCHAR],
            :integer => [ODBC::SQL_INTEGER, ODBC::SQL_SMALLINT],
            :decimal => [ ODBC::SQL_NUMERIC, ODBC::SQL_DECIMAL],
            :float => [ODBC::SQL_DOUBLE, ODBC::SQL_REAL],
            :datetime => [ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
            :timestamp => [ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
            :time => [ODBC::SQL_TYPE_TIME, ODBC::SQL_TIME, 
              ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
            :date => [ODBC::SQL_TYPE_DATE, ODBC::SQL_DATE,
              ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP],
            :binary => [ ODBC::SQL_LONGVARBINARY, ODBC::SQL_VARBINARY],          
            :boolean => [ODBC::SQL_BIT, ODBC::SQL_TINYINT, ODBC::SQL_SMALLINT,
              ODBC::SQL_INTEGER]         
          }
          
          # MySQL:                       
          # Mapping of :boolean to ODBC::SQL_BIT is removed because it does not
          # work with the BIT datatype in MySQL 5.0.3 or later.
          # - Prior to MySQL 5.0.3: BIT was a synonym for TINYINT(1).
          # - MySQL 5.0.3: BIT datatype is supported only for MyISAM tables,
          #   not InnoDB tables (which ActiveRecord requires for transaction 
          #   support).
          # - Ruby ODBC Bridge attempts to fetch SQL_BIT column to SQL_C_LONG.
          #   With MySQL ODBC driver (3.51.12)
          #   - 'select b from ...' returns 0 for a bit value of 0x1
          #   - 'select hex(b) from ...' returns 1 for a bit value of 0x1                    
          if @dbmsName == :mysql  
            map[:boolean].delete(ODBC::SQL_BIT) { raise ActiveRecordError, "SQL_BIT not found" }
          end
          
          map
        end
        
        # Creates a Hash describing a mapping from an abstract type to a
        # DBMS native type for use by #native_database_types
        #
        # rNativeTypeDescs = array of rows from SQLGetTypeInfo result set
        #                   all mapping to the same ODBC SQL type
        def nativeTypeMapping (abstractType, rNativeTypeDescs)
          res = {}
          if abstractType == :primary_key
            # The appropriate SQL for :primary_key is hard to derive as
            # ODBC doesn't provide any info on a DBMS's native syntax for
            # autoincrement columns. So we use a lookup instead.
            val = @@dbmsLookups.get_info(@dbmsName, @dbmsMajorVer, :primary_key)
            res = val 
          else
            nativeTypeDesc = rNativeTypeDescs[0]
            # If more than one native type corresponds to the SQL type we're
            # handling, the type in the first descriptor should be the
            # best match, because the ODBC specification states that
            # SQLGetTypeInfo returns the results ordered by SQL type and then by 
            # how closely the native type maps to that SQL type.
            # But, for :text and :binary, select the native type with the
            # largest capacity.
            if [:text, :binary].include?(abstractType)
              rNativeTypeDescs.each do |ntd|
                # Compare SQLGetTypeInfo:COLUMN_SIZE values
                nativeTypeDesc = ntd if nativeTypeDesc[2] < ntd[2]
              end
            end
            
            res[:name] = nativeTypeDesc[0] # SQLGetTypeInfo: TYPE_NAME
            createParams = nativeTypeDesc[5]
            # Depending on the column type, the CREATE_PARAMS keywords can
            # include length, precision or scale.
            if (createParams && createParams.strip.length > 0 &&
                  ![:decimal].include?(abstractType))
              unless @dbmsName == :db2 && ["BLOB", "CLOB"].include?(res[:name])
                # HACK: 
                # Omit the :limit option for DB2's CLOB and BLOB types, as the
                # :limit value set from SQLGetTypeInfo(COL_SIZE) is 2GB.
                # The max. length for these types defaults to 1MB if the
                # length specifier is omitted.
                res[:limit] = nativeTypeDesc[2] # SQLGetTypeInfo: COL_SIZE
              end
              
              # The max row length in Ingres is typically around 2008 bytes,
              # depending on the default page size.
              # Limit the reported max length of the native type which maps to
              # :string to 255, instead of the actual max length of 2000.
              # This is done to reduce the chances of add_column() exceeding 
              # the maximum row length and Ingres returning an error.
              # 
              # Similarly with DB2. The max row length is typically around 4005
              # bytes.
              # 
              # Similarly with Sybase, reduce the max. :string length from 2000
              # to 255, to avoid add_index exceeding the max. allowed index size
              # of 1250 bytes when creating a composite index.
              res[:limit] = 255 if [:ingres, :sybase, :db2, :progress, :progress89].include?(@dbmsName) && abstractType == :string
            end					
          end
          res
        end
        
        def last_insert_id(table, sequence_name, stmt = nil)
          # This method must be overridden in module ODBCExt.
          # Each DBMS supported by this ODBCAdapter supplies its own version in 
          # file vendor/odbcext_#{dbmsName}.rb        
          raise NotImplementedError, "last_insert_id is an abstract method"
        end
        
        # Converts a result set value from an ODBC type to an ActiveRecord
        # generic type.
        def convertOdbcValToGenericVal(value)
          # When fetching a result set, the Ruby ODBC driver converts all ODBC 
          # SQL types to an equivalent Ruby type; with the exception of
          # SQL_TYPE_DATE, SQL_TYPE_TIME and SQL_TYPE_TIMESTAMP.
          #
          # The conversions below are consistent with the mappings in
          # ODBCColumn#mapSqlTypeToGenericType and Column#klass.
          res = value
p "convertOdbcValToGenericVal:#{value}"
          case value
          when ODBC::TimeStamp
            res = Time.gm(value.year, value.month, value.day, value.hour, 
              value.minute, value.second)
          when ODBC::Time
            now = DateTime.now
            res = Time.gm(now.year, now.month, now.day, value.hour, 
              value.minute, value.second)
          when ODBC::Date
            res = Date.new(value.year, value.month, value.day)
          end
          res
        end
        
        # In general, ActiveRecord uses lowercase attribute names. This may
        # conflict with the database's data dictionary case.
        #
        # The ODBCAdapter uses the following conventions for databases 
        # which report SQL_IDENTIFIER_CASE = SQL_IC_UPPER:
        # * if a name is returned from the DBMS in all uppercase, convert it
        #   to lowercase before returning it to ActiveRecord.
        # * if a name is returned from the DBMS in lowercase or mixed case, 
        #   assume the underlying schema object's name was quoted when 
        #   the schema object was created. Leave the name untouched before 
        #   returning it to ActiveRecord.
        # * before making an ODBC catalog call, if a supplied identifier is all
        #   lowercase, convert it to uppercase. Leave mixed case or all 
        #   uppercase identifiers unchanged.
        # * columns created with quoted lowercase names are not supported. 
        
        # Converts an identifier to the case conventions used by the DBMS.
        def dbmsIdentCase(identifier)
          # Assume received identifier is in ActiveRecord case.
          case @dsInfo.info[ODBC::SQL_IDENTIFIER_CASE]
          when ODBC::SQL_IC_UPPER
            identifier =~ /[A-Z]/ ? identifier : identifier.upcase
          else
            identifier
          end
        end
        
        # Converts an identifier to the case conventions used by ActiveRecord.
        def activeRecIdentCase(identifier)
          # Assume received identifier is in DBMS's data dictionary case.        
          case @dsInfo.info[ODBC::SQL_IDENTIFIER_CASE]
          when ODBC::SQL_IC_UPPER
            identifier =~ /[a-z]/ ? identifier : identifier.downcase
          else
            identifier
          end
        end
        
        # Gets ODBCColumn descriptor for specified column
        def getODBCColumnDesc(table_name, column_name)
          col = nil
          columns(table_name, column_name).each do |colDesc|
            if colDesc.name == column_name
              col = colDesc
              break
            end
          end
          col
        end
        
        # Gets and caches SQLGetTypeInfo result set
        def getDbTypeInfo
          return @typeInfo if @typeInfo
          
          begin
            stmt = @connection.types
            @typeInfo = stmt.fetch_all
          rescue Exception => e
            @logger.unknown("exception=#{e}") if @@trace
            raise ActiveRecordError, e.message
          ensure
            stmt.drop unless stmt.nil?
          end
          @typeInfo
        end
        
        # Simulating sequences
        def create_sequence(name, start_val = 1) end
        def drop_sequence(name) end
        def next_sequence_value(name) end
        def ensure_sequences_table() end
        
      end # class ODBCAdapter
      
      #---------------------------------------------------------------------
      
      class ODBCColumn < Column #:nodoc:
        
        def initialize (name, tableName, default, odbcSqlType, nativeType, 
            null = true, limit = nil, scale = nil, dbExt = nil, 
            booleanColSurrogate = nil, nativeTypes = nil)          
          begin
            require "#{dbExt}"
            self.extend ODBCColumnExt
          rescue MissingSourceFile
            # Assume the current DBMS doesn't require extensions to ODBCColumn
          end
          
          @name, @null = name, null
          
          @precision = extract_precision(odbcSqlType, limit)
          @scale = extract_scale(odbcSqlType, scale)          
          @limit = limit
          
          # nativeType is DBMS type used for column definition
          # sql_type assigned here excludes any length specification
          @sql_type = @nativeType = String.new(nativeType)
          @type = mapSqlTypeToGenericType(odbcSqlType, @nativeType, @scale, booleanColSurrogate, limit,
            nativeTypes)
p "name=>#{@name}, type=>#{@type}"
          # type_cast uses #type so @type must be set first
          
          # The MS SQL Native Client ODBC driver wraps defaults in parentheses 
          # (contrary to the ODBC spec). 
          # e.g. '(1)' instead of '1', '(null)' instead of 'null'
          if default =~ /^\((.+)\)$/ then default = $1 end
          
          if self.respond_to?(:default_preprocess, true)
            default_preprocess(nativeType, default)
          end
          
          @default = type_cast(default)
          @table = tableName
          @primary = nil
          @autounique = self.respond_to?(:autoUnique?, true) ? autoUnique? : false
        end
        
        # Casts a value (which is a String) to the Ruby class 
        # corresponding to the ActiveRecord abstract type associated 
        # with the column.
        #
        # See Column#klass for the Ruby class corresponding to each 
        # ActiveRecord abstract type.
        #
        # When casting a column's default value:
        #   nil => no default value specified
        #   "'<value>'" => string default value
        #   "NULL" => default value of NULL
        #   "TRUNCATED" => default value can't be represented without truncation
        #
        # Microsoft's SQL Native Client ODBC driver may return '(null)'
        # as a column default, instead of NULL, contrary to the ODBC spec'
        # It also wraps other default values in parentheses.
        def type_cast(value)
          return nil if value.nil? || value =~ 
            /(^\s*[(]*\s*null\s*[)]*\s*$)|(^\s*truncated\s*$)/i
          super
        end
                
        private
        
        # Maps an ODBC SQL type to an ActiveRecord abstract data type
        #
        # c.f. Mappings in ConnectionAdapters::Column#simplified_type based on
        # native column type declaration
        #
        # See also:
        # Column#klass (schema_definitions.rb) for the Ruby class corresponding
        # to each abstract data type.
        def mapSqlTypeToGenericType (odbcSqlType, nativeType, scale, 
            booleanColSurrogate, rawPrecision, nativeTypes)
          if booleanColSurrogate && booleanColSurrogate.upcase.index(nativeType.upcase)
            fullType = nativeType.dup
            if booleanColSurrogate =~ /\(\d+(,\d+)?\)/ && rawPrecision
              fullType << "(#{rawPrecision}"
              fullType << ",#{scale}" if $1 && scale
              fullType << ")"
            end
            return :boolean if fullType.casecmp(booleanColSurrogate) == 0
          end
          
p "mapSqlTypeToGenericType:#{odbcSqlType}"
p "#{ODBC::SQL_BIT}"
          case odbcSqlType
          when ODBC::SQL_BIT then :boolean            
          when ODBC::SQL_CHAR, ODBC::SQL_VARCHAR then :string
          when ODBC::SQL_LONGVARCHAR then :text
          when ODBC::SQL_WCHAR, ODBC::SQL_WVARCHAR then :string
          when ODBC::SQL_WLONGVARCHAR then :text            
          when ODBC::SQL_TINYINT, ODBC::SQL_SMALLINT, ODBC::SQL_INTEGER, 
              ODBC::SQL_BIGINT then :integer            
          when ODBC::SQL_REAL, ODBC::SQL_FLOAT, ODBC::SQL_DOUBLE then :float
            # If SQLGetTypeInfo output of ODBC driver doesn't include a mapping 
            # to a native type from SQL_DECIMAL/SQL_NUMERIC, map to :float
          when ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC then scale.nil? || scale == 0 ? :integer : 
            nativeTypes[:decimal].nil? ? :float : :decimal             
          when ODBC::SQL_BINARY, ODBC::SQL_VARBINARY, 
              ODBC::SQL_LONGVARBINARY then :binary            
            # SQL_DATETIME is an alias for SQL_DATE in ODBC's sql.h & sqlext.h
          when ODBC::SQL_DATE, ODBC::SQL_TYPE_DATE, 
              ODBC::SQL_DATETIME then :date
          when ODBC::SQL_TIME, ODBC::SQL_TYPE_TIME then :time
          when ODBC::SQL_TIMESTAMP, ODBC::SQL_TYPE_TIMESTAMP then :timestamp            
          when ODBC::SQL_GUID then :string					            
          else
            # when SQL_UNKNOWN_TYPE
            # (ruby-odbc driver doesn't support following ODBC SQL types:
            #  SQL_WCHAR, SQL_WVARCHAR, SQL_WLONGVARCHAR, SQL_INTERVAL_xxx)
            msg = "Unsupported ODBC SQL type [" << odbcSqlType.to_s << "]"
            raise ActiveRecordError, msg
          end
        end

        def extract_precision(odbcSqlType, odbcPrecision)
          # Ignore the ODBC precision of SQL types which don't take
          # an explicit precision when defining a column
          case odbcSqlType
          when ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC then odbcPrecision
          end
        end

        def extract_scale(odbcSqlType, odbcScale)
          # Ignore the ODBC scale of SQL types which don't take
          # an explicit scale when defining a column
          case odbcSqlType
          when ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC then odbcScale ? odbcScale : 0
          end
        end
        
      end # class ODBCColumn
      
    end # module ConnectionAdapters
  end # module ActiveRecord
  
  #-------------------------------------------------------------------------
rescue LoadError
  module ActiveRecord # :nodoc:
    class Base
      def self.odbc_connection(config) # :nodoc:
        raise LoadError, "The Ruby ODBC module could not be loaded."
      end
    end
  end
end
