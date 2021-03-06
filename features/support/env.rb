PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../../config/boot")

require 'capybara/cucumber'
require 'rspec/expectations'
require 'capybara'
require 'capybara/dsl'

Capybara.default_driver = :selenium
Capybara.app_host = 'http://0.0.0.0:9292'
World(Capybara)

##
# You can handle all padrino applications using instead:
#   Padrino.application
Capybara.app = ProgramasSiconv.tap { |app|  }

Before do
  Programa.delete_all
end
