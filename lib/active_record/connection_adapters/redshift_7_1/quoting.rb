# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Redshift
      module Quoting
        # Escapes binary strings for bytea input to the database.
        def escape_bytea(value)
          @raw_connection.escape_bytea(value) if value
        end

        # Unescapes bytea output from a database to the binary string it represents.
        # NOTE: This is NOT an inverse of escape_bytea! This is only to be used
        # on escaped binary output from database drive.
        def unescape_bytea(value)
          @raw_connection.unescape_bytea(value) if value
        end

        # Quotes strings for use in SQL input.
        def quote_string(s) # :nodoc:
          @raw_connection.escape(s)
        end

        # Checks the following cases:
        #
        # - table_name
        # - "table.name"
        # - schema_name.table_name
        # - schema_name."table.name"
        # - "schema.name".table_name
        # - "schema.name"."table.name"
        def quote_table_name(name)
          Utils.extract_schema_qualified_name(name.to_s).quoted
        end

        def quote_table_name_for_assignment(_table, attr)
          quote_column_name(attr)
        end

        # Quotes column names for use in SQL queries.
        def quote_column_name(name) # :nodoc:
          PG::Connection.quote_ident(name.to_s)
        end

        # Quotes schema names for use in SQL queries.
        def quote_schema_name(name)
          PG::Connection.quote_ident(name)
        end

        # Quote date/time values for use in SQL input.
        def quoted_date(value) # :nodoc:
          result = super

          if value.year <= 0
            bce_year = format('%04d', -value.year + 1)
            result = "#{result.sub(/^-?\d+/, bce_year)} BC"
          end
          result
        end

        # Does not quote function default values for UUID columns
        def quote_default_value(value, column) # :nodoc:
          if column.type == :uuid && value =~ /\(\)/
            value
          else
            quote(value, column)
          end
        end

        def quote(value)
          case value
          when Type::Binary::Data
            "'#{escape_bytea(value.to_s)}'"
          when Float
            if value.infinite? || value.nan?
              "'#{value}'"
            else
              super
            end
          else
            super
          end
        end

        def type_cast(value)
          case value
          when Type::Binary::Data
            # Return a bind param hash with format as binary.
            # See http://deveiate.org/code/pg/PGconn.html#method-i-exec_prepared-doc
            # for more information
            { value: value.to_s, format: 1 }
          else
            super
          end
        end
      end
    end
  end
end
