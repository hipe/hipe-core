# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{hipe-core}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mark Meves"]
  s.date = %q{2009-11-19}
  s.description = %q{core library for the hipe family of products.  data-structure related utilities.
      rudimentary natural language production.  exception factories.  struct diff.
      fun for the whole family.}
  s.email = %q{mark.meves@gmail.com}
  s.extra_rdoc_files = [
    "MIT-LICENSE.txt",
    "History.txt"
  ]
  s.files = [
    ".gitignore",
    "History.txt",
    "MIT-LICENSE.txt",
    "Rakefile.rb",
    "Thorfile",
    "lib/hipe-core.rb",
    "lib/hipe-core/ascii-typesetting.rb",
    "lib/hipe-core/date-range.rb",
    "lib/hipe-core/exception-like.rb",
    "lib/hipe-core/fun-summarize.rb",
    "lib/hipe-core/inspector.rb",
    "lib/hipe-core/io.rb",
    "lib/hipe-core/io/buffer-string.rb",
    "lib/hipe-core/lingual.rb",
    "lib/hipe-core/logger.rb",
    "lib/hipe-core/range.rb",
    "lib/hipe-core/reflection.rb",
    "lib/hipe-core/struct-diff.rb",
    "lib/hipe-core/test/bacon-extensions.rb",
    "spec/README.md",
    "spec/bacon-test-strap.rb",
    "spec/rcov.opts",
    "spec/spec.opts",
    "spec/spec_ascii-typesetting.rb",
    "spec/spec_lingual.rb",
    "spec/spec_struct-diff.rb",
    "spec/struct-diff/fixtures/diff1.marshal"
  ]
  s.homepage = %q{http://github.com/hipe/hipe-core}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{core library for the hipe family of products}
  s.test_files = [
    "spec/bacon-test-strap.rb",
    "spec/spec_ascii-typesetting.rb",
    "spec/spec_lingual.rb",
    "spec/spec_struct-diff.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rools>, [">= 0.4"])
    else
      s.add_dependency(%q<rools>, [">= 0.4"])
    end
  else
    s.add_dependency(%q<rools>, [">= 0.4"])
  end
end
