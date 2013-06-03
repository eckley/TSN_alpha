if Rails.env == 'production'
  Paperclip::Attachment.default_options.merge!(
      :storage => :s3,
      :s3_credentials => {
          :bucket => APP_CONFIG['AWS_BUCKET'],
          :access_key_id => APP_CONFIG['AWS_ACCESS_KEY_ID'],
          :secret_access_key => APP_CONFIG['AWS_SECRET_ACCESS_KEY'],
      },
      :url => ':s3_alias_url',
      :s3_host_alias => APP_CONFIG['AWS_CDN_domain'],
      #:path => '/:class/:attachment/:id_partition/:style/:filename',
      :s3_headers => { 'Expires' => 1.day.from_now.httpdate },
      :path => '/:class/:id_:timestamp.:style.:extension'
  )
end




Paperclip.interpolates(:timestamp) do |attachment, style|
  attachment.instance_read(:updated_at).to_i
end