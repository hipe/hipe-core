require 'rubygems'
require 'rake'

begin
  gem 'jeweler', '~> 1.4'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|    
    gem.name      = 'hipe-core'
    gem.summary   = %q{core library for the hipe family of products (deprecated!)}      
    gem.description  = <<-EOS.strip
    core library for the hipe family of products.  data-structure related utilities.
    rudimentary natural language production.  exception factories.  struct diff.
    fun for the whole family.  (copy paste the stuff you need there is a lot of cruft here)
    EOS
            
    gem.email     = "chip.malice@gmail.com"
    gem.homepage  = "http://github.com/hipe/hipe-core"
    gem.authors   = [ "Chip Malice" ]
    gem.bindir    = ""
    # gem.bindir    = 'bin'     NO! the files in bin are for development only
    gem.date      = %q{2009-11-19}  
    # gem.rubyforge_project = 'none'    

  end
  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end

desc "hack turns the installed gem into a symlink to this directory"

task :hack do
  kill_path = %x{gem which hipe-core}
  kill_path = File.dirname(File.dirname(kill_path))
  new_name  = File.dirname(kill_path)+'/ok-to-erase-'+File.basename(kill_path)
  FileUtils.mv(kill_path, new_name, :verbose => 1)
  this_path = File.dirname(__FILE__)
  FileUtils.ln_s(this_path, kill_path, :verbose => 1)
end
