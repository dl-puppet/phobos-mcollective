class MCollective::Application::Shell < MCollective::Application
  description "MCollective Distributed Shell"
  usage <<-EOF
  mco shell <CMD>

  The CMD is a string

  EXAMPLES:
    mco shell uptime
EOF

  def post_option_parser(configuration)
    if ARGV.size == 0
       raise "You must pass a command!"
    end

    if ARGV.size > 1
      raise "Please specify the command as one argument in single quotes."
    else
      command = ARGV.shift
      configuration[:command] = command
    end
  end

  def validate_configuration(configuration)
    if MCollective::Util.empty_filter?(options[:filter])
      print "Do you really want to send this command unfiltered? (y/n): "
      STDOUT.flush

      # Only match letter "y" or complete word "yes" ...
      exit! unless STDIN.gets.strip.match(/^(?:y|yes)$/i)
    end
  end

  def main
    $0 = "mco"
    command = configuration[:command]

    mc = rpcclient("shell")
    mc.agent_filter(configuration[:agent])
    mc.discover :verbose => true

    puts "\n"

    mc.execute(:cmd => command) do |node|
      sender = node[:senderid]
      exitcode = node[:body][:data][:exitcode]
      output = node[:body][:data][:stdout]
      error = node[:body][:data][:stderr]

      if (output.empty?)
        puts "Host: #{sender}"
        puts "Exitcode: #{exitcode}"
      end

        if !(output.empty?)
          puts "===================================================================================="
          puts "Host: #{sender}"
          puts "Exitcode: #{exitcode}"
          puts "===================================================================================="
          puts "Output:"
          puts output
          puts "===================================================================================="
        end

        if !(error.empty?)
          puts "===================================================================================="
          puts "Host: #{sender}"
          puts "Exitcode: #{exitcode}"
          puts "===================================================================================="
          puts "Error:"
          puts error
          puts "===================================================================================="
        end

        puts "\n"
    end

    mc.disconnect
  end
end
