# bacon spec/hipe-core/spec_interfacey.rb
require 'bacon'
require 'ruby-debug'
require 'hipe-core/interfacey'
require 'hipe-core/interfacey/optparse-bridge'

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

      "]}.should.raise Cli::AbilityParse::Error
      e.message.should.equal "expecting valid name at:\n9lives\n^"
    end
    it "should barf on invalid name again" do
      e = lambda{ Ability["9lives"]}.should.raise(
        Cli::AbilityParse::Error)
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
        [--template=<template_directory>]
        [-l] [-s] [--no-hardlinks] [-q] [-n] [--bare] [--mirror]
        [-o <name>] [-u <upload-pack>] [--repository <repository>]
        [--depth <depth>] [--recursive] [--alph[a]a[=<jesus>]] [--]
        i am the remainder of the string
      COMMAND
      arr = AssociativeArray.new
      parse = Cli::AbilityParse.new
      parse.parse_off Cli::SwitchParameter, definition, arr
      have = arr * ' '
      want = "[--template <template_directory>] [-l] [-s] [--no-hardlinks]"<<
      " [-q] [-n] [--bare] [--mirror] [-o <name>] [-u <upload-pack>] "<<
       "[--repository <repository>]"<<
      " [--depth <depth>] [--recursive] [-a [jesus]] [--]"
      have.should.equal want
      definition.strip.should.equal "i am the remainder of the string"
    end
    it "should parse requireds and optionals" do
      ability = Ability["  jeebis-beavis [-a] [--b[c]d] <eee> <fff> [<ggg>] "]
      ability.name.should.equal "jeebis-beavis"
      ability.parameters.size.should.equal 5
      ["eee","fff"].each do |name|
        param = ability.parameters[name]
        param.name.should.equal name
        param.cli_type.should.equal :required
        param.required?.should.equal true
        param.argument_required?.should.equal true
      end
      param = ability.parameters["ggg"]
      param.name.should.equal "ggg"
      param.required?.should.equal false
      param.argument_required?.should.equal true
    end
  end
end
