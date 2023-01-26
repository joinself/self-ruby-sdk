def run_example(d, name)
  # r = Chat::Runner.new(@client, @prompt)
  module_name = d.tr('/', '').split('_').collect(&:capitalize).join
  r = Object.const_get(module_name)::Runner.new(@client, @prompt)


  box = TTY::Box.frame(padding: 3, align: :left, title: {top_left: "#{name} example"} ) do
    r.help
  end
  print "\n" + box + "\n"
  r.run

  puts ""
  puts ""
  if @prompt.yes?("Do you want to check the code for this example?")
    path = "#{d}/lib.rb"
    box = TTY::Box.frame(padding: 3, align: :left, title: {top_left: "#{name} example", bottom_right: "examples/#{path}"} ) do
      get_example_source(path)
    end
    print "\n" + box + "\n"
  end

  if @prompt.yes?("Awesome! Do you want to try a different example?")
    load_main_menu
  else
    exit
  end
end
