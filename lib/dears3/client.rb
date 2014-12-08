require 'aws-sdk'
require 'thor'

class DearS3::Client
  include ::Thor::Shell

  def initialize s3_connection
    @s3 = s3_connection
    @bucket = nil

    set_bucket
  end

  def sync path
    say "Uploading files to bucket '#{ bucket.name }'."
    walk_and_upload path
    say "Done syncing bucket."
  end

  def configure_website
    files = bucket.objects.map { |obj| obj.key }
    say "Files currently in your bucket:"
    say files.join(" | "), :green
    index_doc = ask "Pick your bucket's index document:"
    error_doc = ask "Pick your bucket's error document:"
    say "Publishing your bucket. This may take a while..."
    bucket.configure_website do |cfg|
      cfg.index_document_suffix = index_doc
      cfg.error_document_key = error_doc # TODO: Make this optional
    end
    say "Bucket published at #{ bucket.url }."
  end

  def remove_website
    bucket.remove_website_configuration
    say "Removed #{ bucket.name } from the web."
  end

  private

  attr_accessor :bucket
  attr_reader :s3

  def set_bucket
    # TODO: Optionally configure bucket name and enforce DNS requirements
    # see https://forums.aws.amazon.com/thread.jspa?messageID=570880
    bucket_name = File.basename(Dir.getwd).gsub '_', '-'
    self.bucket = s3.buckets[bucket_name]

    unless bucket.exists?
      say "Creating bucket '#{ bucket.name }'"
      s3.buckets.create(bucket.name, acl: :bucket_owner_full_control)
    end
  end

  def walk_and_upload path
    entries = Dir.entries path
    entries.each do |entry|
      next if entry == File.basename(__FILE__) || entry[0] == '.' 
      nested_entry = (path == "." ? entry : "#{ path }/#{ entry }")
      if File.directory? nested_entry
        walk_and_upload nested_entry
        next
      else
        upload nested_entry
      end
    end
  end

  def upload entry
    new_object = bucket.objects[entry]

    begin
      if new_object.exists?
        # Strip opening and closing "\" chars from AWS-formatted etag
        etag_is_same = new_object.etag[1..-2] == Digest::MD5.hexdigest(File.read entry)

        if etag_is_same
          say "\tUnchanged: #{ entry }", :blue
          return
        else
          # TODO: Confirm overriding files
          say "\tUpdating: '#{ entry }'", :yellow
        end
      else
        say "\tUploading: '#{ entry }'", :green
      end
      content_type = MIME::Types.type_for(entry).to_s
      new_object.write File.open entry, content_type: content_type
    rescue ::AWS::S3::Errors::Forbidden
      say "Access denied!", :red
      say "Make sure your credentials are correct and your bucket name isn't already taken by someone else."
      say "Note: AWS bucket names are shared across all users."
      say
      abort
    end
  end
end

