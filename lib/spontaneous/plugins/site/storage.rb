# encoding: UTF-8


# storage :s3 do |config|
#   config[:provider] = "AWS",
#   config[:aws_access_key_id] = "key",
#   config[:aws_secret_access_key] = "secret",
#   config[:region] = 'eu-west-1'
#   config[:bucket] => "name_of_bucket"
#   config[:accepts] => "image/*"
# end

# storage :another_local do |config|
#   config.update({
#     :provider => "Local"
#   })
# end
module Spontaneous::Plugins
  module Site
    module Storage
      module ClassMethods
        def storage(mimetype = nil)
          instance.storage(mimetype)
        end

        def local_storage
          instance.local_storage
        end
      end

      module InstanceMethods
        def storage(mimetype = nil)
          storage_for_mimetype(mimetype)
        end

        def storage_for_mimetype(mimetype)
          storage_backends.detect { |storage| storage.accepts?(mimetype) }
        end

        def local_storage
          storage_backends.select { |storage| storage.local? }
        end

        def storage_backends
          @storage_backends ||= configure_storage
        end

        def configure_storage
          storage_backends = []
          storage_settings = config[:storage] || []
          storage_settings.each do |name, config|
            backend = Spontaneous::Storage.create(config)
            storage_backends << backend
          end
          storage_backends << default_storage
        end

        def default_storage
          Spontaneous::Storage::Local.new(Spontaneous.media_dir, '/media', accepts=nil)
        end
      end
    end
  end
end
