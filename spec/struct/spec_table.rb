# bacon -n'\(tbl\d+\)' spec/struct/table.rb
require 'extlib' # for String#t(), and Extlib::Inflection.humanize


require 'ruby-debug'
require 'hipe-core/struct/table'
require 'ostruct'


describe Hipe::Table do
  it "should work (tbl1)" do
    @table = Hipe::Table.make do
      field(:name){|item| item.name}
      field(:height){|item| "%2.2f feet".t(item.height) }
      field(:birthday,:visible=>false ){|item| item.birthday.strftime('%Y-%m-%d %H:%I:%S') }
      labelize{|name| Extlib::Inflection.humanize(name) }
      renderer(:ascii) do |r|
        r.left  = '| ';  r.right = ' |'; r.separator   = ' | '
        r.header{|text| x.gsub(' ','_')}
        r.top{|width| '_' * width }
        r.bottom{|width| '-' * width }
        r.after_header = r.bottom
      end
      # renderers[:json] = MyJsonRenderer
    end

    @table.list = [
      OpenStruct.new(:name=>'larry',:birthday=>DateTime.parse('1902-10-5'),:height=>5.75),
      OpenStruct.new(:name=>'mo',:birthday=>DateTime.parse('1897-06-19'),:height=>6.0),
      OpenStruct.new(:name=>'curly',:birthday=>DateTime.parse('1895-03-04'),:height=>5.9876)
    ]

    target = <<-HERE.gsub(/^    /,'')
    _____________________
    |  Name |    Height |
    ---------------------
    | larry | 5.75 feet |
    |    mo | 6.00 feet |
    | curly | 5.99 feet |
    ---------------------
    HERE

    have =  @table.render(:ascii)
    have.should.equal target
  end

  it "should allow you to change the look of it (tbl2)" do
    @table.renderer(:ascii) do |r|
      r.top{|w| %{+#{'-'*([w-2,0].max)}+} }
      r.bottom = r.top
      r.after_header = r.top
    end
    @table.field[:birthday].show()
    @table.field[:name].min_width = 10
    have = @table.render(:ascii)
    target = <<-HERE.gsub(/^    /,'')
    +----------------------------------------------+
    |       Name |    Height |            Birthday |
    +----------------------------------------------+
    |      larry | 5.75 feet | 1902-10-05 00:12:00 |
    |         mo | 6.00 feet | 1897-06-19 00:12:00 |
    |      curly | 5.99 feet | 1895-03-04 00:12:00 |
    +----------------------------------------------+
    HERE
    have.should.equal target
  end


  it "should do some attractive, reasonable defaults (tbl3)" do

    Hipe::Table.make do
      field(:name){|x| x[:name]}
      field(:height){|x| "%2.2f feet".t(x[:height]) }
      self.list = [
        {:name=>'larry', :height=>5.75    },
        {:name=>'mo',    :height=>6.0     },
        {:name=>'curly', :height=>5.9876  }
      ]
    end.render(:ascii).should.equal <<-HERE.gsub(/^    /,'')
    +---------------------+
    |   name |     height |
    +---------------------+
    |  larry |  5.75 feet |
    |     mo |  6.00 feet |
    |  curly |  5.99 feet |
    +---------------------+
    HERE

  end
end
