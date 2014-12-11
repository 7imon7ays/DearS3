require 'rspec'
require 'bundler/setup'
require 'thor'

Bundler.setup

require 'dears3'

#AWS.stub!
RSpec.configure do |config|
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
end

