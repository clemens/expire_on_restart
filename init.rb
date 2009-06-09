require 'expire_on_restart'

ActionController::Base.send(:include, ExpireOnRestart::ExpirationHelper)
ActionView::Base.send(:include, ExpireOnRestart::ExpirationHelper)
ActionView::Helpers::AssetTagHelper.send(:include, ExpireOnRestart::AssetCacheExpirationHelper)

ExpireOnRestart::RestartExpirator.instance.expire_marked_files