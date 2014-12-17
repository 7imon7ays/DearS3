module DearS3
  class Cli
    class AuthenticationHelper
      include ::Thor::Shell

      def initialize authentication
        @authentication = authentication
      end

      def connect
        begin
          authentication.connect
        rescue Errno::ENOENT
          say "Credentials file not found. Please run 's3:auth' to authenticate.", :red
          abort
        end
      end

      def save_credentials! credentials
        authentication.create_credentials_file! credentials
      end

      def maybe_get_credentials
        if File.exists?(credentials_path) && !override_credentials?
          nil
        else
          request_credentials
        end
      end

      private

      attr_reader :authentication

      def request_credentials
        access_key_id = ask "Please enter your AWS access key id:"
        secret_access_key = ask "Please enter your AWS secret access key:", echo: false
        say

        { access_key_id: access_key_id, secret_access_key: secret_access_key }
      end

      def override_credentials?
        choice = ask("Override existing '.aws.json' file? (y/n):")
        %w( y yes Y ok OK ).include? choice
      end

      def credentials_path
        File.expand_path '~/.aws.json'
      end
    end
  end
end
