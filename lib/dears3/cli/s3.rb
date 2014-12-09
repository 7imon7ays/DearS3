require 'thor'

module DearS3
  class Cli
      class S3 < Thor
        desc "upload", "Deploy current and nested directories to S3"
        option :publish, type: :boolean, default: false # Optionally publish to the web
        def upload
          s3_upload = open_connection

          s3_upload.sync "."
          s3_upload.configure_website if options[:publish]
        end

        desc "publish", "Publish bucket as a website"
        option :off, type: :boolean, default: false
        def publish
          s3_upload = open_connection
          options[:off] ?
            s3_upload.remove_website : s3_upload.configure_website
        end

        desc "auth", "Save AWS credentials in home directory"
        def auth
          s3_auth = DearS3::Auth.new
          s3_auth.authenticate
        end

        private
        
        def open_connection
          s3_auth = DearS3::Auth.new
          s3_connection = s3_auth.connect
          DearS3::Client.new s3_connection
        end
      end
  end
end

