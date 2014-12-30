require 'dears3/cli/authentication_helper'
require 'dears3/cli/client_helper'
require 'thor'

module DearS3
  class Cli
    class S3 < Thor
      desc "upload", "Deploy current and nested directories to S3"
      def upload
        client_helper.upload
      end

      desc "publish", "Publish bucket as a website"
      def publish
        client_helper.publish
      end

      desc "unpublish", "Take bucket off the www"
      def unpublish
        client_helper.unpublish
      end

      desc "auth", "Save AWS credentials in home directory"
      def auth
        # If credentials file already exists and user doesn't
        # choose to override, do nothing.
        if credentials = authentication_helper.maybe_get_credentials
          authentication_helper.save_credentials! credentials
        end
      end

      private

      def client_helper
        @client_helper ||= ClientHelper.new s3_client
      end
      
      def s3_client
        @s3_client ||= DearS3::Client.instance.with s3_connection
      end

      def s3_connection
        authentication.connect
      end

      def authentication_helper
        @auhentication_helper ||= DearS3::Cli::AuthenticationHelper.new authentication
      end
      
      def authentication
        @authentication ||= DearS3::Authentication.instance
      end
    end
  end
end

