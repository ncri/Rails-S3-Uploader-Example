module UploadsHelper

  require 'base64'
  require 'openssl'
  require 'digest/sha1'

  def s3_uploader(options = {})
    s3_config_filename = "#{RAILS_ROOT}/config/amazon_s3.yml"
    config = YAML.load_file(s3_config_filename)

    bucket            = config[RAILS_ENV]['bucket_name']
    access_key_id     = config[RAILS_ENV]['access_key_id']
    secret_access_key = config[RAILS_ENV]['secret_access_key']

    options[:key] ||= ''
    options[:content_type] ||= '' # Defaults to binary/octet-stream if blank
    options[:acl] ||= 'public-read'
    options[:expiration_date] ||= 10.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    options[:max_filesize] ||= 2.megabyte

    id = options[:id] ? "_#{options[:id]}" : ''

    policy = Base64.encode64(
      "{'expiration': '#{options[:expiration_date]}',
        'conditions': [
          {'bucket': '#{bucket}'},
          ['starts-with', '$key', '#{options[:key]}'],
          {'acl': '#{options[:acl]}'},
          {'success_action_status': '201'},
          ['content-length-range', 0, #{options[:max_filesize]}],
          ['starts-with', '$Filename', ''],
          ['starts-with', '#{options[:content_type]}', '']
        ]
      }").gsub(/\n|\r/, '')

    signature = Base64.encode64(
                  OpenSSL::HMAC.digest(
                    OpenSSL::Digest::Digest.new('sha1'),
                    secret_access_key, policy)).gsub("\n","")

    out = ""

    out << "\n"
    out << link_to("<strong>" + (options[:text] || 'Upload File(s)') + '</strong>', '#', :id => "upload_link#{id}")
    out << "\n"
    out << content_tag(:ul, '', :id => "uploader_file_list#{id}", :class => 'uploader_file_list' )
    out << "\n"

    out << javascript_tag("window.addEvent('domready', function() {

      /**
       * Uploader instance
       */

      var up#{ id } = new FancyUpload3.S3Uploader( 'uploader_file_list#{id}', '#upload_link#{id}', {
                                                   host: '#{request.host_with_port}',
                                                   bucket: '#{bucket}',
                                                   typeFilter: #{options[:type_filter] ? "{" + options[:type_filter] + "}" : 'null' },
                                                   fileSizeMax: #{options[:max_filesize]},
                                                   access_key_id: '#{access_key_id}',
                                                   policy: '#{policy}' ,
                                                   signature: '#{signature}',
                                                   key: '#{options[:key]}',
                                                   id: '#{id}',
                                                   acl: '#{options[:acl]}',
                                                   https: #{options[:https] ? 'true' : 'false'},
                                                   validateFileNamesURL: '#{options[:validate_filenames_url]}',
                                                   onUploadComplete: #{options[:on_upload_complete] || 'null'},
                                                   onUploadCompleteURL: '#{options[:on_complete]}',
                                                   onUploadCompleteMethod: '#{options[:on_complete_method]}',
                                                   formAuthenticityToken: '#{form_authenticity_token}',
                                                   verbose: #{options[:verbose] ? 'true' : 'false' }
      })
    });")

  end


end
