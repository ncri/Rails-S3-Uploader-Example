module UploadsHelper

  #  Creates an upload link to a Fancy Upload S3 File Uploader
  #
  #  required parameters:
  #
  #  key                       s3 'path' to uploaded files
  #
  #
  #  optional parameters:                       Default/Explanation
  #
  #  text                      link text, default: 'Upload File(s)'
  #
  #  s3_config_filename        filename of s3 config yaml file (full path), defaults to "#{RAILS_ROOT}/config/amazon_s3.yml"
  #
  #  content_type              binary/octet-stream
  #
  #  acl                       public-read
  #
  #  expiration_date           10.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
  #
  #  max_filesize              2.megabyte
  #
  #  https                     false
  #
  #  id                        uploader id, necessary in case there is more than one uploader on the page
  #
  #  typefilter                filetype filter for file select dialog (see FancyUpload documentation)
  #
  #  validate_file_names_url   URL to a function for testing for existing filenames on s3 and creating uniq prefixes for those files.
  #                            The parameter file_names passed to the function contains the selected file names (comma separated).
  #                            The function needs to return a uniq prefix for each filename that exists on the server and 'file_ok'
  #                            for filenames that are not existing on the server. Example: ['_1', 'file_ok', '_3', ...].
  #                            (I do prefer postfixes to prefixes, but I didn't manage to get FancyUpload to like postfixes.)
  #                            The array needs to be returned in json format.
  #                            !!! If not specified, files on s3 with the same filename as the uploaded file are overwritten !!!
  #
  #  on_complete_url           URL to call after a file upload has completed.
  #                            Paramters passed are: upload_element_id, filename, filesize, filename_prefix
  #                            default: nil
  #
  #  on_complete_method        http method to be used when calling on_complete_url, default: 'get'
  #
  #  verbose                   Show debug output for fancyupload in js console, default: false
  #
  #
  def s3_uploader(options = {})
    options[:s3_config_filename] ||= "#{RAILS_ROOT}/config/amazon_s3.yml"
    config = YAML.load_file(options[:s3_config_filename])
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
                                                   onUploadCompleteURL: '#{options[:on_complete_url]}',
                                                   onUploadCompleteMethod: '#{options[:on_complete_method]}',
                                                   formAuthenticityToken: '#{form_authenticity_token}',
                                                   verbose: #{options[:verbose] ? 'true' : 'false' }
      })
    });")

  end


end
