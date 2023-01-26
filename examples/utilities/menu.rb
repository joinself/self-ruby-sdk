def cleanup_example_name(input)
  input.sub("_", " ").sub("/", " ").sub("dl ", "Dynamic link ").sub("qr ", "QR ").capitalize.strip
end

def load_main_menu
  multiline_text = <<-MSG
Select the feature you want to try.
  MSG

  @prompt.select(multiline_text) do |menu|
    @examples.each do |d|
      name = cleanup_example_name(d)
      menu.choice "#{name} example", -> { run_example(d, name) }
    end
    menu.choice "Exit", -> { return }
  end
end
