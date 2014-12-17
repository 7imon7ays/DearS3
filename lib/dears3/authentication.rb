require 'aws-sdk'
require 'oj'
require 'thor'
require 'singleton'

class DearS3::Authentication
  include Singleton

  # TODO: Give option to upload once without storing credentials.
  def connect
    # TODO: Raise error if no credentials file available
    ::AWS::S3.new aws_credentials
  end

  def create_credentials_file! credentials
    File.open credentials_path, "w" do |f|
      f.write credentials.to_json
      f.write "\n"
    end
  end

  private

  def aws_credentials
    ::Oj.load File.read credentials_path
  end

  def credentials_path
    File.expand_path '~/.aws.json'
  end
end

