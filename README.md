# rosh

* https://github.com/turboladen/rosh


## DESCRIPTION:

Ruby Object Shell.  Serves two purposes:

1. Provides an API for programmatically operating on a local or remote OS.
1.  A shell that feels like a Unix shell, but returns Ruby objects.

The latter provides functionality for [screenplay](https://github.com/turboladen/screenplay),
a configuration management solution that allows for deploying apps and managing
OSes.

## FEATURES/PROBLEMS:

### Manage Hosts over SSH

Whether you're using the API or Shell, Rosh's main job is to let you
operate/manage your local and remote hosts.  Since often times accomplishing a
task means operating on multiple hosts, Rosh can manage multiple hosts--much in
the same way that you might SSH in to box1, do some things, then SSH in to box2
and do some other things.

### API

Rosh provides access API access to manage your OS from an object-oriented
perspective:

* File system objects
    * Directories
    * Files
    * Links
* Package managers
    * [Apt](https://wiki.debian.org/Apt)
    * [dpkg](https://wiki.debian.org/dpkg)
    * [Homebrew](http://brew.sh)
    * [Yum](http://yum.baseurl.org)
* Packages
    * [Homebrew](http://brew.sh)
    * [Debian](https://wiki.debian.org/DebianPackage)
    * [RPM](http://www.rpm.org)
* Service managers
    * [init](http://en.wikipedia.org/wiki/Init)
    * [launchctl](http://en.wikipedia.org/wiki/Launchd)
* Services
    * [init](http://en.wikipedia.org/wiki/Init)
    * [launchd](http://en.wikipedia.org/wiki/Launchd)
* Users
* Groups

At the core of this are the Rosh::Shells.  When used locally, the shell will use
Ruby libraries for interacting with the OS, thus allowing you to work with Ruby
objects that represent these OS things.  When used with remote hosts, the shell
will do everything over SSH, yet still let you treat those OS things as Ruby
objects.

This makes it easy for you to use Ruby to manage your OSes.

### Shell

Rosh also provides a Unix shell replacement that provides standard built-in
commands, where those commands return the same Ruby objects that the API
returns:

* cat
* cd
* cp
* env
* exec
* history
* ls
* ps
* pwd

If you execute a command that is not defined in the Rosh shell, Rosh will use
your PATH setting and try to find the executable there.

The shell also adds the `ch` (change host) command, which lets you quickly
change which host you're working with--similar to SSHing into another remote
host.  Rosh lets you define these ahead of time though, sort of like a wrapper
to your SSH config stuff.

The shell also lets you run Ruby code, in-line, just as if you were running IRB.
This lets you work with the Ruby object that was returned from a command.

Additionally, the Rosh shell provides:

* Command completion
* Command history


## SYNOPSIS:

### API

#### Working with hosts

The Rosh::Host object is the core to Rosh.  At the very basic level, Rosh gives
you access to some attributes of that object:

```ruby
Rosh.add_host('my_server.example.com', host_label: :box1, user: 'admin')
Rosh[:box1].class                   # => Rosh::Host
Rosh[:box1].hostname
# (prompts for password)
# => 'my_server.example.com'
Rosh[:box1].user                    # => 'admin'
Rosh[:box1].operating_system        # => :darwin
Rosh[:box1].distribution_version    # => "10.8.4"
Rosh[:box1].kernel_version          # => "12.4.0"
Rosh[:box1].architecture            # => :x86_64
```

#### Working with file system objects

This part of Rosh's API attempts to mimic Ruby's [File](http://rdoc.info/stdlib/core/File)
and [Dir](http://rdoc.info/stdlib/core/Dir) libraries, regardless if you're
working with local or remote files.

A Rosh::Host object gives you access to the file system via the `#fs` accessor.
Through that, it lets you work with files and directories as objects.


```ruby
Rosh[:box1].fs['/Users/admin'].class        # => Rosh::Host::FileSystemObjects::RemoteDir
Rosh[:box1].fs['/Users/admin'].exists?      # => true
Rosh[:box1].fs['/Users/admin'].directory?   # => true
Rosh[:box1].fs['/Users/admin'].file?        # => false
Rosh[:box1].fs['/Users/admin'].owner        # => 'joe'
Rosh[:box1].fs['/Users/admin'].group        # => 'staff'
Rosh[:box1].fs['/Users/admin'].basename     # => 'admin'
```

The file object doesn't have to exist yet to use it.  In this sense, Rosh
behaves a bit like an ORM.

```ruby
# Directories
Rosh[:box1].fs.directory('/tmp/neat_dir').exists?      # => false
Rosh[:box1].fs.directory('/tmp/neat_dir').save         # => true
Rosh[:box1].fs.directory('/tmp/neat_dir').exists?      # => true
Rosh[:box1].fs.directory('/tmp/neat_dir').owner        # => 'admin'

# Files
Rosh[:box1].fs.file('/tmp/neat_file').exists?      # => false
Rosh[:box1].fs.file('/tmp/neat_file').contents     # => nil
Rosh[:box1].fs.file('/tmp/neat_file').contents = "Hi!"
Rosh[:box1].fs.file('/tmp/neat_file').save         # => true
Rosh[:box1].fs.file('/tmp/neat_file').contents     # => "Hi!"
Rosh[:box1].fs.file('/tmp/neat_file').exists?      # => true
```

You're not limited to the above syntax; you could rewrite the above like:

```ruby
# Directories
dir = Rosh[:box1].fs.directory('/tmp/neat_dir')
dir.class        # => Rosh::Host::FileSystemObjects::RemoteDir
dir.exists?      # => false
dir.save         # => true
dir.exists?      # => true
dir.owner        # => 'admin'

# Files
file = Rosh[:box1].fs.file('/tmp/neat_file')
file.class        # => Rosh::Host::FileSystemObjects::RemoteFile
file.exists?      # => false
file.contents     # => nil
file.contents = "Hi!"
file.save         # => true
file.contents     # => "Hi!"
file.exists?      # => true
```

When working with files, you may want to use a template for generating
the file.

```erb
# config.erb

export DB_USER=<%= username %>
```

```ruby
%w[george wanda].each do |user|
  file = Rosh[:box1].fs.file("/users/#{user}/.neat_config")
  file.from_template('config.erb', username: user)
  file.save
  puts file.contents    # => "# config.erb\n\nexport DB_USER=george\n"
                        # => "# config.erb\n\nexport DB_USER=wanda\n"
end
```

#### Working with packages managers and packages

Rosh objectifies not only your OS's package manager, but the packages
themselves.  It makes some assumptions of which package manager you're using
based on your OS (which it detects when it needs to), thus you don't have to
worry about which OS you're dealing with before dealing with it.

```ruby
# Update the package manager's local cache.
Rosh[:box1].packages.update_definitions

# Upgrade outdated packages.
Rosh[:box1].packages.upgrade_packages

# Install a specific package.
Rosh[:box1].packages['curl'].installed?             # => false
Rosh[:box1].packages['curl'].install                # => true
Rosh[:box1].packages['curl'].installed?             # => true
Rosh[:box1].packages['curl'].at_latest_version?     # => true

# ...or
curl = Rosh[:box1].packages['curl']
curl.installed?             # => false
curl.install                # => true
curl.installed?             # => true
curl.at_latest_version?     # => true
```

#### Working with service managers and services

```ruby
Rosh[:box1].services.list                   # => (A potentially long list)
Rosh[:box1].services['httpd'].status

```

### Shell

    $ rosh
    [turboladen@localhost:turboladen]$ ls
      ["./atlassian-ide-plugin.xml", ./bin, "./Gemfile", "./Gemfile.lock", "./History.rdoc", ./lib, "./Rakefile", "./README.rdoc", "./rosh.gemspec", ./spec]
    [turboladen@localhost:turboladen]$ result = ls
      ["./atlassian-ide-plugin.xml", ./bin, "./Gemfile", "./Gemfile.lock", "./History.rdoc", ./lib, "./Rakefile", "./README.rdoc", "./rosh.gemspec", ./spec]
    [turboladen@localhost:turboladen]$ result.first.class
      Rosh::File
    [turboladen@localhost:turboladen]$ result.first.mode
      100644
    [turboladen@localhost:turboladen]$ result.first.content
      <atlassian-ide-plugin>
      <project-configuration>
        <servers />
      </project-configuration>
    </atlassian-ide-plugin>
    [turboladen@localhost:turboladen]$ some_var = "hi"
      hi
    [turboladen@localhost:turboladen]$ some_var
      hi

## REQUIREMENTS:

* RubyGems
    * awesome_print
    * colorize
    * highline
    * log_switch
    * plist
    * net-ssh
    * net-scp
    * sys-proctable


## INSTALL:

* gem install rosh

(Not yet released)

## LICENSE:

(The MIT License)

Copyright (c) 2013 Steve Loveless

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
