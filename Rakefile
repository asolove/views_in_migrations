require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "views_in_migrations"
    gem.summary = %Q{Use MySQL views to back ActiveRecord models, and define them in your migrations.}
    gem.description = %Q{ViewsInMigrations provides helper methods for using MySQL views behind ActiveRecord models. It helps you define, modify, test, and refresh your views. And it also handles correctly dumping the definitions to schema.rb.}
    gem.email = "asolove@gmail.com"
    gem.homepage = "http://github.com/asolove/views_in_migrations"
    gem.authors = ["asolove"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency('active_record', '>= 2.3.2')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "views_in_migrations #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
