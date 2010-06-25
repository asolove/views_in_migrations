require 'rubygems'
require 'active_record'

module ViewsInMigrations
  
  def self.views_supported?
    ActiveRecord::Base.connection.send(:supports_views?)
  rescue
    false
  end
  
  module SchemaStatements
    def drop_view(view_name, options = {})
      execute "DROP VIEW IF EXISTS #{quote_table_name(view_name)}"
    end
    
    def create_view(view_name, *args)
      options = {}
      
      if args.first.kind_of?(String)
        select_statement = args.first
        options = args.extract_options!
      end
      
      if options[:force] && table_exists?(view_name)
        drop_view(view_name, options)
      end
      
      if select_statement
        options[:options] ||= " WITH CHECK OPTION"
        view_sql =  "CREATE VIEW #{quote_table_name(view_name)} AS "
        view_sql << select_statement
        view_sql << "#{options[:options]}"
        execute view_sql
      end
    end
    
    def view_definition(view_name) 
      select_value(%{
        SELECT view_definition FROM information_schema.views 
        WHERE table_name = #{view_name.inspect} 
        AND table_schema = #{current_database.inspect}
      })      
    end
    
    def define_view(view_name, for_dump = false)
      sanitize_view_sql(view_definition(view_name), for_dump)
    end
    
    def sanitize_view_sql(view_sql, for_dump = false)
      sql = view_sql.dup

      # remove newlines
      sql.gsub!(/\n|^\s*|\s*$/,'')
      # we can just use SELECT *...
      sql.gsub!(/SELECT .* FROM/i, "SELECT * FROM" )
      sql.gsub!('where', 'WHERE')   
      
      if for_dump
        #insert newlines for readability
        sql.gsub!(/(from|where|in|\() /i, '\n\1 ')
      end
      
      sql
    end
    
    def views
      select_values( %{
        select table_name 
        FROM information_schema.views 
        WHERE table_schema = #{current_database.inspect}
      }) 
    end
    
    def table_is_view?(table_name)
      views.include?(table_name)
    end
    
    def refresh_view(view_name)
      raise "#{view_name.inspect} is not a view" unless table_is_view?(view_name)
      sql = define_view(view_name)
      drop_view(view_name)
      create_view(view_name,sql)      
    end
    
    def refresh_views
      views.each{|view| refresh_view!(view)}     
    end
    
    def assert_presence_of_column(klass_name, column)
      unless current_column_names_for(klass_name).include?(column.to_s)
        raise Mysql::Error.new("Invalid view on #{klass_name}, missing required column: #{column}")
      end
    end
    
    def assert_absence_of_column(klass_name, column)
      if current_column_names_for(klass_name).include?(column.to_s)
        raise Mysql::Error.new("Invalid view on #{klass_name}, has invalid column: #{column}")
      end
    end
    
    def current_column_names_for(klass_name)
      klass = klass_name.to_s.classify.constantize
      klass.reset_column_information
      klass.column_names
    end
  end
  
  module SchemaDumper
    # Only output normal tables in the body of the schema
    def table_with_views_in_migrations(table, stream)
      table_without_views_in_migrations(table, stream) unless @connection.table_is_view?(table)
    end
    
    # After all table definitions, print view definitions
    def trailer_with_views_in_migrations(stream)
      views(stream)
      
      trailer_without_views_in_migrations(stream)
    end
    
    def views(stream)
      @connection.views.each do |table|
        stream.puts "if ViewsInMigrations.use_views?(current_database)"        
          view(table,stream)        
        stream.puts "else\n\n"        
          table_without_views_in_migrations(table, stream)        
        stream.puts "end\n\n"
      end
    end
    
    def view(view_name, stream)      
      stream.puts <<-WARNING
  #############################################################
  # Warning: SchemaDumper cannot determine view dependencies! #
  #   You may have to manually reorder your views to run      #
  # `rake db:schema:load` successfully.                       #
  #############################################################
  
  WARNING
  
      out = StringIO.new
      out.puts "  create_view #{view_name.inspect}, %{"   
  
      sql = @connection.define_view(view_name, true)  
  
      sql.split('\n').each do |line|
        out.puts "    #{line}"
      end
  
      out.puts "  }, :force => true\n\n"
  
      out.rewind
      stream.print out.read      
    end
  end
end

if ViewsInMigrations.views_supported?

  ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
    include ViewsInMigrations::SchemaStatements  
  end

  ActiveRecord::SchemaDumper.class_eval do
    include ViewsInMigrations::SchemaDumper  
    alias_method_chain :table, :views_in_migrations
    alias_method_chain :trailer, :views_in_migrations
  end

end