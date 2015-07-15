require 'bundler/setup'
# Bundler.setup
require './lib/rosh'
require 'securerandom'

h = Rosh.add_host 'localhost'
h.idempotent_mode = true
f = h.fs[file: 'ttt']
contents_before = f.contents

puts "contents before setting: #{contents_before}"
contents_after = SecureRandom.base64
f.contents = contents_after.dup
puts "state: #{f.state} (should be 'dirtied')"
puts "contents: #{f.contents} (should be '#{contents_after}')"
puts "persisted? #{f.persisted?} (should be false)"
f.save
puts "state: #{f.state} (should be 'persisted')"
puts "contents: #{f.contents} (should be '#{contents_after}')"
puts "persisted? #{f.persisted?} (should be true)"

# puts "copying..."
# new_file = f.copy_to 'tuv'
# puts "new file: #{new_file}"
# exit if new_file.is_a? Symbol
puts 'copying...'
f.copy_to 'tuv' do |new_file|
  puts "new file: #{new_file}"
  puts "new file is a: #{new_file.class}"

  puts 'hardlinking...'
  new_file.hard_link_to 'tzzhard' do |linked_file|
    puts "linked file: #{linked_file}"
    puts "linked file is a: #{linked_file.class}"
    puts 'reading hardlink...'
    puts linked_file.read(2)

    puts 'readlines...'
    p linked_file.readlines
  end
end
