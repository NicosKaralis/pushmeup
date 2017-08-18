require 'rails/generators/base'

module Pushmeup
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def copy_locale
        copy_file '../../../config/locales/en.yml', 'config/locales/pushmeup.en.yml'
      end
    end
  end
end