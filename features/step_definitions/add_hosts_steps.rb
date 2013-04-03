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
    result[column['Command']] = @rosh.hosts[@ip].shell.send(column['Command'].to_sym)

    result
  end
end

And(/^get a response as a Ruby object$/) do
  @results.each do |command, result|
    result.should be_a Rosh::CommandResult

    case command
    when 'pwd'
      result.ruby_object.should match %r[/\w+/\w+]
    end
  end
end

When(/^I set the "(.*?)" option to "(.*?)"$/) do |ssh_option, value|
  @rosh.hosts[@ip].set ssh_option.to_sym => value
end
