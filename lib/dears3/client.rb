require 'aws-sdk'
require 'thor'
require 'digest/md5'
require 'mime/types'
require 'singleton'

class DearS3::Client
  include Singleton

  def set_bucket
    name = generate_bucket_name
    self.bucket = s3.buckets[name]

    if new_bucket?
      s3.buckets.create(bucket.name, acl: :bucket_owner_full_control)
    end
    bucket.name
  end

  def new_bucket?
    !bucket.exists?
  end

  def bucket_name
    bucket.name
  end

  def with s3_connection
    @bucket = nil
    @s3 = s3_connection
    self
  end

  def walk_and_upload path, status_proc = nil
    entries = Dir.entries path
    entries.each do |entry|
      next if entry == File.basename(__FILE__) || entry[0] == '.' 
      nested_entry = (path == "." ? entry : "#{ path }/#{ entry }")
      if File.directory? nested_entry
        walk_and_upload nested_entry, status_proc
        next
      else
        upload nested_entry, status_proc
      end
    end
  end

  def configure_website index_doc, error_doc
    bucket.configure_website do |cfg|
      cfg.index_document_suffix = index_doc
      cfg.error_document_key = error_doc # TODO: Make this optional
    end

    bucket.policy = generate_policy
    # bucket web address hard-coded for now
    "http://dears3.s3-website-us-east-1.amazonaws.com/"
    # bucket.url
  end

  def generate_policy
    policy = AWS::S3::Policy.new
    resources = "arn:aws:s3:::#{ bucket_name }/*"
    policy.allow(actions: [:get_object], resources: resources, principals: :any)
    policy
  end

  def files_in_bucket
    bucket.objects.map { |obj| obj.key }
  end

  def remove_website
    bucket.remove_website_configuration
    bucket.url
  end

  private

  attr_accessor :bucket
  attr_reader :s3

  def generate_bucket_name
    # TODO: Add DNS and AWS requirements
    # - more than 3 chars, unique
    # - https://forums.aws.amazon.com/thread.jspa?messageID=570880
    File.basename(Dir.getwd).gsub '_', '-'
  end

  def upload entry, status_proc = nil
    object = bucket.objects[entry]

    if object.exists? && entry_is_unchanged?(entry, object)
      status_proc.call entry, :unchanged
    elsif object.exists?
      status_proc.call entry, :update
    else
      status_proc.call entry, :upload
    end

    content_type = ::MIME::Types.type_for(entry).to_s
    object.write File.open entry, content_type: content_type
  end

  def entry_is_unchanged? entry, object
    # Is object etag equal to the MD5 digest of the entry?
    # Strip opening and closing "\" chars from AWS-formatted etag
    object.etag[1..-2] == ::Digest::MD5.hexdigest(File.read entry)
  end
end

