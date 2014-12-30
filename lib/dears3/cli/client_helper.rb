module DearS3
  class Cli
    class ClientHelper
      include ::Thor::Shell

      def initialize s3_client
        @s3_client = s3_client

        name = get_bucket_name

        s3_client.set_bucket name
      end

      def upload
        bucket_name = s3_client.bucket_name

        say "Uploading files to bucket '#{ bucket_name }'."

        begin
          s3_client.walk_and_upload ".", status_proc
        rescue ::AWS::S3::Errors::Forbidden
          alert_access_denied
          exit
        end
        say "Done syncing bucket."
      end

      def current_dir_to_bucket_name
        File.basename(Dir.getwd).gsub('_', '-')
      end

      def publish
        bucket_files = s3_client.files_in_bucket

        if bucket_files.empty?
          abort "Bucket is empty. Please upload at least one file before publishing"
        end

        say "Files currently in your bucket:"
        say bucket_files.join(" | "), :green
        index_doc = request_doc "Pick your bucket's index document:"
        error_doc = request_doc "Pick your bucket's error document:"

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

      def get_bucket_name
        bucket_name = default_bucket_name

        if s3_client.validate_bucket_name(bucket_name)
          bucket_name = ask "Please select your bucket's name:"
        end

        while error = s3_client.validate_bucket_name(bucket_name)
          bucket_name = ask "#{ error } bucket name. Please select another:"
        end

        if s3_client.new_bucket? bucket_name
          choice = ask "Creating new bucket '#{ bucket_name }'. Continue? (y/n/abort)" end

        return get_bucket_name if %w( n no N No NO ).include? choice
        exit if choice == "abort"

        bucket_name
      end

      def default_bucket_name
        File.basename(Dir.getwd).gsub('_', '-').downcase
      end

      def request_doc request_message
        doc = ask request_message
        files_in_bucket = s3_client.files_in_bucket

        until files_in_bucket.include? doc
          say "No such file in your bucket. Please choose one from this list:"
          doc = ask files_in_bucket.join(" | ") + "\n", :green
        end

        doc
      end

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
