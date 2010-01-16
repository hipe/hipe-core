# Naming Conventions in this folder

Bacon tests are named "spec_\*.rb" and any rspec tests will be named "rspec_\*.rb"

We want all of the appropriate tests to be under the hipe-core folder 
because of the strict name mappings used in our .autotest configuration.

The `bacon -a` (bacon 1.1.0) command looks for files of the following pattern: 
  "test/**/test_*.rb"
  "test/**/spec_*.rb"
  "spec/**/spec_*.rb"
  
although at times we want to make an rspec-specific test (for struct diffs, for e.g.)