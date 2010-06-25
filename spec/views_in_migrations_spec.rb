require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ViewsInMigrations" do
  before(:all) do
    ActiveRecord::Base.connection.create_table("people") do |t|
      t.id
      t.string :name
      t.boolean :manager
    end
    
    ActiveRecord::Base.connection.create_view("managers", "SELECT * from people where manager IS TRUE")
    class Person < ActiveRecord::Base; end;
    class Manager < ActiveRecord::Base; end;
    
    @conn = ActiveRecord::Base.connection
  end
  
  it "can use views with mysql" do
    ViewsInMigrations.views_supported?.should == true
  end
  
  it "knows a view from a table" do
    @conn.table_is_view?("people").should == false
    @conn.table_is_view?("managers").should == true
  end
  
  it "quietly drops a non-existing view" do
    @conn.drop_view("doesn't_exist")
  end
  
  it "creates a view" do
    lambda { @conn.create_view("drones", "SELECT * from people where manager IS FALSE") }.should_not raise_error()
    @conn.views.should include("drones")
  end
  
  it "drops an existing view" do
    lambda { @conn.drop_view("drones")}.should_not raise_error()
    @conn.views.should_not include("drones")
  end
  
  it "finds view rows and creates AR instances" do
    @bob = Person.create :name => "Bob", :manager => true
    @bob.id.should == Manager.find_by_name("Bob").id
  end
  
  it "gets column names from the database" do
    Manager.should_receive(:reset_column_information).and_return(true)
    Manager.should_receive(:column_names).and_return(["a"])
    
    @conn.current_column_names_for(Manager).should == ["a"]
  end
  
  it "asserts the presence and absence of columns" do
    lambda { @conn.assert_presence_of_column Manager, :name
             @conn.assert_absence_of_column  Manager, :fake }.should_not raise_error
    lambda { @conn.assert_presence_of_column Manager, :fake }.should raise_error(Mysql::Error)
    lambda { @conn.assert_absence_of_column  Manager, :name }.should raise_error(Mysql::Error)
  end
  
  it "returns the definition of a view" do
    # @conn.view_definition('managers').should ??
  end
  
  it "dumps views after tables" do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(@conn, stream)
    stream.rewind
    schema = stream.read
    schema.index("managers").should > schema.index("people")
  end
end