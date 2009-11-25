module UploadsHelper

  def s3_uploader(options = {})
    filename = "#{RAILS_ROOT}/config/amazon_s3.yml"
    config = YAML.load_file(filename)

    bucket            = config['bucket_name']
    access_key_id     = config['access_key_id']
    secret_access_key = config['secret_access_key']

    key             = options[:key] || ''
    content_type    = options[:content_type] || ''
    acl             = options[:acl] || 'public-read'
    expiration_date = (options[:expiration_date] || 10.hours).from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    max_filesize    = options[:max_filesize] || 2.megabyte

    policy = Base64.encode64(
      "{'expiration': '#{expiration_date}',
        'conditions': [
          {'bucket': '#{bucket}'},
          ['starts-with', '$key', '#{key}'],
          {'acl': '#{acl}'},
          {'success_action_status': '201'},
          ['content-length-range', 0, #{max_filesize}],
          ['starts-with', '$Filename', ''],
          ['starts-with', '#{content_type}', '']
        ]
      }").gsub(/\n|\r/, '')

    signature = Base64.encode64(
                  OpenSSL::HMAC.digest(
                    OpenSSL::Digest::Digest.new('sha1'),
                    secret_access_key, policy)).gsub("\n","")

    out = ""
    out << %(
      <form action="https://#{bucket}.s3.amazonaws.com/" method="post" enctype="multipart/form-data" id="upload-form">
      <input type="hidden" name="key" value="#{key}/${filename}">
      <input type="hidden" name="AWSAccessKeyId" value="#{access_key_id}">
      <input type="hidden" name="acl" value="#{acl}">
      <input type="hidden" name="policy" value="#{policy}">
      <input type="hidden" name="signature" value="#{signature}">
      <input type="hidden" name="success_action_status" value="201">
      <input type="hidden" name="Content-Type" value="#{content_type}">
      </form>
    )

    out << "\n"
    out << link_to('Upload File(s)', '#',:id=> 'upload_link')
    out << "\n"
    out << content_tag(:ul, '', :id => 'uploader_file_list')
    out << "\n"

    out << javascript_tag("window.addEvent('domready', function() {

    /**
     * Uploader instance
     */
    var up = new FancyUpload3.Attach('uploader_file_list', '#upload_link', {
      path: 'http://your_app_domain/javascripts/fancyupload/source/Swiff.Uploader.swf',
      url: 'https://#{bucket}.s3.amazonaws.com/',
      fieldName: 'file',
      data: $('upload-form').toQueryString(),

      fileSizeMax: 2000 * 1024 * 1024,

      //verbose: true,

      onSelectFail: function(files) {
        files.each(function(file) {
          new Element('li', {
            'class': 'file-invalid',
            events: {
              click: function() {
                this.destroy();
              }
            }
          }).adopt(
            new Element('span', {html: file.validationErrorMessage || file.validationError})
          ).inject(this.list, 'bottom');
        }, this);
      },

      onFileComplete: function(file) {
        if (file.response.code == 201 || file.response.code == 0){
          file.ui.element.highlight('#e6efc2');
          file.ui.element.children[2].setStyle('display','none');
          file.ui.element.children[3].setStyle('display','none');
        }
      },

      onFileError: function(file) {
        if (file.response.code != 201){
          file.ui.cancel.set('html', 'Retry').removeEvents().addEvent('click', function() {
            file.requeue();
            return false;
          });

          new Element('span', {
            html: file.errorMessage,
            'class': 'file-error'
          }).inject(file.ui.cancel, 'after'); }
      },

      onFileRequeue: function(file) {
        file.ui.element.getElement('.file-error').destroy();

        file.ui.cancel.set('html', 'Cancel').removeEvents().addEvent('click', function() {
          file.remove();
          return false;
        });

        this.start();
      }

      });

    });")

  end


end
