Given(/^there is a host at "(.*?)"$/) do |ip|
  @ip = ip
end

When(/^I add that host to the shell$/) do
  @rosh = Rosh.new

  if @ip == 'localhost'
    @rosh.add_host @ip
  else
    @rosh.add_host @ip, user: 'vagrant',
      keys: %W[#{Dir.home}/.vagrant.d/insecure_private_key]
  end
end

Then(/^I can run commands on it:$/) do |table|
  @results = table.hashes.inject({}) do |result, column|
    command = column['Command'].to_sym
    arg1 = column['Arg1']

    result[command] = if arg1.nil? || arg1.empty?
      @rosh.hosts[@ip].shell.send(command)
    else
      @rosh.hosts[@ip].shell.send(command, arg1)
    end

    result
  end
end

And(/^get a response as a Ruby object$/) do
  @results.each do |command, result|
    result.should be_a Rosh::CommandResult

    case command
    when :pwd
      result.ruby_object.should match %r[/\w+/\w+]
    when :cat
    else
      raise "Got unexpected command: #{command}"
    end
  end
end

When(/^I set the "(.*?)" option to "(.*?)"$/) do |ssh_option, value|
  @rosh.hosts[@ip].set ssh_option.to_sym => value
end
