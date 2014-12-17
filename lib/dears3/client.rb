require 'aws-sdk'
require 'thor'
require 'digest/md5'
require 'mime/types'
require 'singleton'

class DearS3::Client
  include Singleton

  def initialize s3_connection
    @s3 = s3_connection
    @bucket = nil

    set_bucket options[:name]
  end

  def sync path
    walk_and_upload path
  end

  def configure_website index_doc, error_doc
    bucket.configure_website do |cfg|
      cfg.index_document_suffix = index_doc
      cfg.error_document_key = error_doc # TODO: Make this optional
    end
    bucket.acl = :public_read
  end

  def remove_website
    bucket.remove_website_configuration
  end

  private

  attr_accessor :bucket
  attr_reader :s3

  def select_bucket_name name
    name || File.basename(Dir.getwd).gsub('_', '-')
  end

  def set_bucket
    self.bucket = s3.buckets[name]

    unless bucket.exists?
      s3.buckets.create(bucket.name, acl: :bucket_owner_full_control)
    end
  end

  # TODO: Check bucket name availability
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
      content_type = ::MIME::Types.type_for(entry).to_s
      new_object.write File.open entry, content_type: content_type
  end

  def entry_is_unchanged? entry
    # Is object etag equal to the MD5 digest of the entry?
    # Strip opening and closing "\" chars from AWS-formatted etag
    new_object.etag[1..-2] == ::Digest::MD5.hexdigest(File.read entry)
  end
end

