require 'aws-sdk'
require 'oj'
require 'thor'

class DearS3::Auth
  include ::Thor::Shell

  def initialize
    @credentials = {}
  end

  # TODO: Give option to upload once without storing credentials.
  def connect
    begin
      return ::AWS::S3.new aws_credentials
    rescue Errno::ENOENT
      say "Credentials file not found. Please run 's3:auth' to authenticate.", :red
      abort
    end
  end

  def authenticate
    if confirm_create_credentials_file?
      request_credentials
      create_credentials_file!
    end
  end

  private

  def aws_credentials
    ::Oj.load File.read credentials_path
  end

  def create_credentials_file!
    File.open credentials_path, "w" do |f|
      f.write @credentials.to_json
      f.write "\n"
    end
  end

  def request_credentials
    @credentials[:access_key_id] = ask "Please enter your AWS access key id:"
    @credentials[:secret_access_key] = ask(
      "Please enter your AWS secret access key:",
      echo: false
    )
    say
  end

  def credentials_path
    File.expand_path "~/.aws.json"
  end

  def confirm_create_credentials_file?
    if File.exists? credentials_path
      override = ask "Override existing '.aws.json' file? (y/n):"
      override == "y"
    else
      true
    end
  end
end

