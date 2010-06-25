# Find source files
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'spec'
require 'spec/autorun'

require 'rubygems'
require 'active_record'

# Establish connection 
conn = { :adapter => 'mysql',
  :database => '',
  :username => 'root', 
  :password => '',
  :encoding => 'utf8' }

conn[:socket] = Pathname.glob(%w[
  /opt/local/var/run/mysql5/mysqld.sock
  /tmp/mysqld.sock
  /tmp/mysql.sock
  /var/mysql/mysql.sock
  /var/run/mysqld/mysqld.sock
]).find { |path| path.socket? }

ActiveRecord::Base.establish_connection(conn)
ActiveRecord::Base.connection.recreate_database("views_in_migrations_test")

conn[:database] = "views_in_migrations_test"
ActiveRecord::Base.establish_connection(conn)

# Must be required after AR connection is established
require 'views_in_migrations'

Spec::Runner.configure do |config|
  
end
