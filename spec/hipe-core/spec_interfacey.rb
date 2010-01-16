# bacon spec/hipe-core/spec_interfacey.rb
require 'bacon'
require 'ruby-debug'
require 'hipe-core/interfacey'

class Bacon::Context
  def skipit(desc)
    puts %{SKIPPING #{desc}}
  end
end

module Hipe::Interfacey
  describe Ability do
    it "should barf on invalid name" do
      e = lambda{ Ability["

        9lives

      "]}.should.raise Ability::DefinitionParse::Error
      e.message.should.equal "expecting valid name at:\n9lives\n^"
    end
    it "should barf on invalid name again" do
      e = lambda{ Ability["9lives"]}.should.raise(
        Ability::DefinitionParse::Error)
      e.message.should.equal "expecting valid name at:\n9lives\n^"
    end
    it "should be happy with good name again" do
      a = Ability["\n\n\t\n nine-lives\n\n "]
      a.name.should.equal "nine-lives"
    end
    it "should be happy with good name again" do
      a = Ability["\n\n\t\n nine-lives"]
      a.name.should.equal "nine-lives"
    end
    it "should be happy with good name again" do
      a = Ability["nine-lives\n\t\s "]
      a.name.should.equal "nine-lives"
    end
    it "should be happy with good name again" do
      a = Ability["nine-lives"]
      a.name.should.equal "nine-lives"
    end
    it "should parse switches (s)" do
      definition = <<-COMMAND
      clone [--template=<template_directory>]
        [-l] [-s] [--no-hardlinks] [-q] [-n] [--bare] [--mirror]
        [-o <name>] [-u <upload-pack>] [--reference <repository>]
        [--depth <depth>] [--recursive] [--alph[a]a[=<jesus>]] [--]
        i am the remainder of the string
      COMMAND
      arr = AssociativeArray.new
      parse = Ability::DefinitionParse.new
      parse.parse_off_switches definition, arr
      (arr * ' ').should.equal 'x'
    end
  end
end
