# rosh

* https://github.com/turboladen/rosh


## DESCRIPTION:

Just a silly little pet project... A shell that feels like BASH, but returns
Ruby objects.

## FEATURES/PROBLEMS:

* commands:
    * cat
    * cd
    * cp
    * history
    * ls
    * ps

* Command completion
* Command history


## SYNOPSIS:

    $ rosh
    [/Users/Steveloveless/Development/projects/rosh]$ ls
      ["./atlassian-ide-plugin.xml", ./bin, "./Gemfile", "./Gemfile.lock", "./History.rdoc", ./lib, "./Rakefile", "./README.rdoc", "./rosh.gemspec", ./spec]
    [/Users/Steveloveless/Development/projects/rosh]$ result = ls
      ["./atlassian-ide-plugin.xml", ./bin, "./Gemfile", "./Gemfile.lock", "./History.rdoc", ./lib, "./Rakefile", "./README.rdoc", "./rosh.gemspec", ./spec]
    [/Users/Steveloveless/Development/projects/rosh]$ result.first.class
      Rosh::File
    [/Users/Steveloveless/Development/projects/rosh]$ result.first.mode
      100644
    [/Users/Steveloveless/Development/projects/rosh]$ result.first.content
      <atlassian-ide-plugin>
      <project-configuration>
        <servers />
      </project-configuration>
    </atlassian-ide-plugin>
    [/Users/Steveloveless/Development/projects/rosh]$ some_var = "hi"
      hi
    [/Users/Steveloveless/Development/projects/rosh]$ some_var
      hi

## REQUIREMENTS:

* RubyGems
    * colorize
    * log_switch
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
