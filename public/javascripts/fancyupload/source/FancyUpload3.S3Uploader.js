// required parameters:
//
// host
// bucket
// access_key_id
// policy
// signature
// key   (s3 'path' to uploaded files)
//
// 
// optional parameters:
//
// https                     (use https for upload - ignored if url is given)
// id                        (uploader id, necessary in case there is more than one uploader on a page)
// acl                       (default = 'public_read')
// validateFileNamesURL
// onUploadCompleteURL
// onUploadCompleteMethod
// formAuthenticityToken     (required if at least one of validateFileNamesURL or onUploadCompleteURL is given)
// url                       (url to amazon bucket, default = 'http://' + options.bucket + '.s3.amazonaws.com/'
// path                      (path to swiff uploader, default = 'http://' + options.host + '/javascripts/fancyupload/source/Swiff.Uploader.swf'
// fieldName                 (default = 'file')
//
// For more options see the FancyUpload3 documentation


FancyUpload3.S3Uploader = new Class({

	Extends: FancyUpload3.Attach,

	options: {
                fieldName: 'file',
                allowDuplicates: true,
                id: '',
                onUploadCompleteMethod: 'get',
                acl: 'public-read',
                https: false
	},

	initialize: function(list, selects, options) {
                options.path = options.path || 'http://' + options.host + '/javascripts/fancyupload/source/Swiff.Uploader.swf'
                var protocol = options.https ? 'https' : 'http'
                options.url = options.url || protocol + '://' + options.bucket + '.s3.amazonaws.com/';

                this.addEvents({'onBeforeStart': this.onBeforeStart,
                                'onSelectFail': this.onSelectFail,
                                'onFileComplete': this.onFileComplete,
                                'onFileError': this.onFileError,
                                'onFileRequeue': this.onFileRequeue
			});

		this.parent(list, selects, options);
	},

	onBeforeStart: function() {
          if (this.options.validateFileNamesURL && this.options.validateFileNamesURL != ''){
            var file_names = [];
            this.fileList.each(function(file, index) {
              if (!file.completeDate){
                file_names.extend([file.name]);
              }
            } );
            var req = new Request({
                          method: 'get',
                          async: false,
                          url: this.options.validateFileNamesURL,
                          data: { 'authenticity_token' : this.options.formAuthenticityToken, 'file_names' : file_names.join(',') } }).send();

            var response = JSON.parse(req.response.text);
          }

          var data = { AWSAccessKeyId: this.options.access_key_id,
                       acl: this.options.acl,
                       policy: this.options.policy,
                       signature: this.options.signature,
                       success_action_status: '201' };
          if (this.options.validateFileNamesURL && this.options.validateFileNamesURL != ''){
            for (var j=response.length-1, i=this.fileList.length-1; i > this.fileList.length - 1 - response.length; i--, j--){
              if (response[j] != 'file_ok'){
                data.key = this.options.key + '/_' + response[j] + '_${filename}';
                this.fileList[i].prefix = response[j];
              }
              else
                data.key = this.options.key + '/${filename}';
              this.fileList[i].setOptions({ data: data });
            }
          }
          else{
            for (i=0; i < this.fileList.length; i++){
              data.key = this.options.key + '/${filename}';
              this.fileList[i].setOptions({ data: data });
            }
          }

        },

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
          file.ui.element.dispose();
          file.ui.element.children[2].setStyle('display','none');
          file.ui.element.children[3].setStyle('display','none');

          if (this.options.onUploadCompleteURL)
            var requestData = { 'upload_element_id' : file.ui.element.id, 'authenticity_token' : this.options.formAuthenticityToken, 'filename' : file.name, 'filesize' : file.size, 'filename_prefix' : file.prefix || '' };
            var request = new Request({ async: false,
                          method: this.options.onUploadCompleteMethod,
                          url: this.options.onUploadCompleteURL,
                          data: requestData });
            request.send();
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


FancyUpload3.S3Uploader.File = new Class({

	Extends: FancyUpload3.Attach.File,

        // Optionally stores a prefix applied to the filename.
        // Used to create a new unique filename to prevent overwriting of files that already exist on S3.
        prefix: ''
});