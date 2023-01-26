require 'rouge'

def get_example_source(path)
  # make some nice lexed html
  source = File.read("./#{path}")
  source = source.split("# printexample", 2).last
  source = source.split("# !printexample", 2).first

  formatter = ::Rouge::Formatters::Terminal256.new(::Rouge::Themes::Gruvbox.new)
  lexer = Rouge::Lexers::Ruby.new

  formatter.format(lexer.lex(source))
end