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

      def save_credentials!
        authentication.create_credentials_file!
      end

      def maybe_get_credentials
        if File.exists? credentials_path && dont_override_credentials?
          nil
        else
          request_credentials
        end
      end

      def request_credentials
        access_key_id = ask "Please enter your AWS access key id:"
        secret_access_key = ask "Please enter your AWS secret access key:", echo: false

        { access_key_id: access_key_id, secret_access_key: secret_access_key }
      end

      def dont_override_credentials?
        choice = ask("Override existing '.aws.json' file? (y/n):") == "y"
        %w( n no N no ).include? choice
      end

      private
      attr_reader :authentication
    end
  end
end
