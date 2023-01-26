require 'dotenv/load'
require 'tty-font'
require 'tty-prompt'
require 'tty-box'
require 'colorize'
require 'colorized_string'
require_relative 'utilities/setup.rb'
require_relative 'utilities/runner.rb'
require_relative 'utilities/source_getter.rb'
require_relative 'utilities/menu.rb'

font = TTY::Font.new(:doom)
puts font.write("SELF quickstart")

@prompt = TTY::Prompt.new
@client = setup_sdk
@examples = []

# Preload examples
Dir['*/'].each do |d|
  file_name = "#{d}/lib.rb"
  next unless File.exist? file_name

  require_relative file_name
  @examples << d
end

# Let's create a connection with Self
load_main_menu
