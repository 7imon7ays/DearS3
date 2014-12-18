module DearS3
  class Cli
    class ClientHelper
      include ::Thor::Shell

      def initialize s3_client
        @s3_client = s3_client
      end

      def upload
        bucket_name = s3_client.bucket_name

        if s3_client.new_bucket?
          say "Creating bucket '#{ bucket_name }'."
        else
          say "Uploading files to bucket '#{ bucket_name }'."
        end

        begin
          s3_client.walk_and_upload ".", status_proc
        rescue ::AWS::S3::Errors::Forbidden
          alert_access_denied
          abort
        end
        say "Done syncing bucket."
      end

      def current_dir_to_bucket_name
        File.basename(Dir.getwd).gsub('_', '-')
      end

      def publish
        say "Files currently in your bucket:"
        say s3_client.files_in_bucket.join(" | "), :green
        index_doc = ask "Pick your bucket's index document:"
        error_doc = ask "Pick your bucket's error document:"
        say "Publishing your bucket. This may take a while..."
        bucket_url = s3_client.configure_website index_doc, error_doc
        say "Bucket published at #{ bucket_url }."
      end

      def unpublish
        bucket_url = s3_client.remove_website
        say "Removed #{ bucket_url } from the web."
      end

      private

      attr_reader :s3_client

      def alert_access_denied
        say "Access denied!", :red
        say "Make sure your credentials are correct and your bucket name isn't already taken by someone else."
        say "Note: AWS bucket names are shared across all users."
        say
      end

      def status_proc
        # TODO: Confirm overriding files
        Proc.new do |entry, status|
          case status
          when :unchanged
            say "\tUnchanged: #{ entry }", :blue
          when :update
            say "\tUpdating: '#{ entry }'", :yellow
          when :upload
          say "\tUploading: '#{ entry }'", :green
          end
        end
      end
    end
  end
end
