# require 'spec'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'
require 'rcov/rcovtask'


desc 'Removes trailing whitespace'
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
end

Rcov::RcovTask.new do |t|
  t.test_files = FileList['spec/spec_*.rb']
  t.verbose = true     # uncomment to see the executed command
  t.rcov_opts = ['--exclude', 'spec,/Library/Ruby/Gems/1.8/gems']
end

RCov::VerifyTask.new(:verify_rcov => :rcov) do |t|
  t.threshold = 80 # Make sure you have rcov 0.7 or higher!
end


# thanks manveru

desc 'Run all bacon specs with pretty output'
task :bacon do
  require 'open3'
  require 'scanf'
  require 'matrix'

  PROJECT_SPECS = FileList[
    'spec/spec_*.rb'
  ]

  specs = PROJECT_SPECS

  some_failed = false
  specs_size = specs.size
  len = specs.map{|s| s.size }.sort.last
  total_tests = total_assertions = total_failures = total_errors = 0
  totals = Vector[0, 0, 0, 0]

  red, yellow, green = "\e[31m%s\e[0m", "\e[33m%s\e[0m", "\e[32m%s\e[0m"
  left_format = "%4d/%d: %-#{len + 11}s"
  spec_format = "%d specifications (%d requirements), %d failures, %d errors"

  load_path = File.expand_path('./lib', __FILE__)

  specs.each_with_index do |spec, idx|
    print(left_format % [idx + 1, specs_size, spec])

    Open3.popen3('bacon', '-I', load_path, spec) do |sin, sout, serr|
      out = sout.read.strip
      err = serr.read.strip

      # this is conventional
      if out =~ /^Bacon::Error: (needed .*)/
        puts(yellow % ("%6s %s" % ['', $1]))
      elsif out =~ /^Spec (precondition: "[^"]*" failed)/
        puts(yellow % ("%6s %s" % ['', $1]))
      elsif out =~ /^Spec require: "require" failed: "(no such file to load -- [^"]*)"/
        puts(yellow % ("%6s %s" % ['', $1]))
      else
        total = nil

        out.each_line do |line|
          scanned = line.scanf(spec_format)

          next unless scanned.size == 4

          total = Vector[*scanned]
          break
        end

        if total
          totals += total
          tests, assertions, failures, errors = total_array = total.to_a

          if tests > 0 && failures + errors == 0
            puts((green % "%6d passed") % tests)
          else
            some_failed = true
            puts(red % "       failed")
            puts out unless out.empty?
            puts err unless err.empty?
          end
        else
          some_failed = true
          puts(red % "       failed")
          puts out unless out.empty?
          puts err unless err.empty?
        end
      end
    end
  end

  total_color = some_failed ? red : green
  puts(total_color % (spec_format % totals.to_a))
  exit 1 if some_failed
end

#
#SPECOPTS  = ['--options', "\"#{File.dirname(__FILE__)}/test/spec.opts\""]
#SPECFILES = FileList['test/**/spec_*.rb']
#
#desc "run all specs"
#Spec::Rake::SpecTask.new do |t|
#  t.spec_opts = SPECOPTS
#  t.spec_files = SPECFILES
#end
#
#desc "Run all specs with rcov"
#Spec::Rake::SpecTask.new(:rcov) do |t|
#  t.spec_opts = SPECOPTS
#  t.spec_files = SPECFILES
#  t.rcov = true
#  t.rcov_opts = lambda do
#    IO.readlines(File.dirname(__FILE__) + "/test/rcov.opts").map {|l| l.chomp.split " "}.flatten
#  end
#end
#
