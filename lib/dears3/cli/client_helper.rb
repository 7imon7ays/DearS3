module DearS3
  class Cli
    class ClientHelper
      include ::Thor::Shell

      def initialize s3_client
        @s3_client = s3_client
      end

      def upload_helper options = {}
        bucket_name = s3_client.set_bucket_name options[:name]

        say "Uploading files to bucket '#{ bucket_name }'."
        s3_client.sync "."
        s3_client.configure_website if options[:publish]
        say "Done syncing bucket."
      end

      def publish_helper
        say "Files currently in your bucket:"
        say files.join(" | "), :green
        index_doc = ask "Pick your bucket's index document:"
        error_doc = ask "Pick your bucket's error document:"
        say "Publishing your bucket. This may take a while..."
        s3_client.configure_website index_doc, error_doc
        say "Bucket published at #{ bucket.url }."
      end

      def unpublish_helper
        s3_client.remove_website
        say "Removed #{ bucket.name } from the web."
      end

      def create_bucket name
        # TODO: Optionally configure bucket name and enforce DNS requirements
        # see https://forums.aws.amazon.com/thread.jspa?messageID=570880
        say "Creating bucket '#{ bucket.name }'"
        s3_client.set_bucket name
      end

      def upload entry
        if entry_name_exists?
          if client.entry_is_unchanged? entry
            say "\tUnchanged: #{ entry }", :blue
          else
            # TODO: Confirm overriding files
            say "\tUpdating: '#{ entry }'", :yellow
          end
        else
          say "\tUploading: '#{ entry }'", :green
        end

        begin
          client.upload entry
        rescue ::AWS::S3::Errors::Forbidden
          alert_access_denied
          abort
        end
      end

      def alert_access_denied
        say "Access denied!", :red
        say "Make sure your credentials are correct and your bucket name isn't already taken by someone else."
        say "Note: AWS bucket names are shared across all users."
        say
      end

      private
      attr_reader :s3_client
    end
  end
end
