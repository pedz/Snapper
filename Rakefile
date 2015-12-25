require 'jasmine'
load 'jasmine/tasks/jasmine.rake'

desc "Make the jsdoc3 documentation for the javascript"
task :jsdoc do
  echo_system "jsdoc --configure doc/conf.json"
end

def exclude_list
  %w{
  .*\.html
  .*\.jpg
  Gemfile
  Gemfile\.lock
  Rakefile
  \.bundle
  \.git
  doc/conf\.json
  doc/javascript
  doc/rdoc
  doc/ri
  doc/yard
  features
  lib/javascript
  lib/stylesheets
  temp
  test\.snap
}.join('|')
end

def echo_system(s)
  system("echo #{s}")
  system(s)
end

desc "Create the Filters file for rdoc to consume"
task :make_filters do
  # We copy filters.rb over to doc/filters which will create a page
  # calle Filters.  We start after the line that contains :startdoc:.
  # When we copy, if the line starts with a #, the # and one space is
  # removed from the line.  If it does not, then two spaces are added
  # making it into a verbatim section.
  from = File.open("lib/filters.rb", "r")
  to = File.open("doc/Filters", "w", 0644)
  copying = false
  from.each_line do |line|
    if copying
      if /\A# /.match(line)
        to.write(line[2 .. -1])
      else
        to.write("  " + line)
      end
    end
    if copying == false && /:startdoc:/.match(line)
      to.write("= Filters\n")
      copying = true
    end
  end
  from.close
  to.close
end

desc "Make the yard documentation"
task :yard => [:make_filters] do
  echo_system [
    "yard",
    "'--title=Snapper'",
    "'--main=README'",
    "--plugin",
    "rspec",
    "'--private'",
    "'--files=doc/Filters'",
    "'--exclude=\\./(#{exclude_list})'",
    "'--output=doc/yard'",
    "lib/*.rb",
    "spec/*.rb"
  ].join(' ')
end

desc "Make the rdoc documentation"
task :rdoc => [:make_filters] do
  echo_system [
    "rdoc",
    "'--all'",
    "'--main=README'",
    "'--exclude=\\./(#{exclude_list})'",
    "'--output=doc/rdoc'"
  ].join(' ')
end

desc "Make the ri documentation"
task :ri => [:make_filters] do
  echo_system [
    "rdoc",
    "'--all'",
    "'--ri'",
    "'--main=README'",
    "'--exclude=\\./(#{exclude_list})'",
    "'--output=doc/ri'"
  ].join(' ')
end

desc "Makes the rdoc, ri, yard, and jsdoc documentation"
task "all-docs" => [ :ri, :jsdoc, :yard ]

desc "Clean up all the documentation directories"
task "clean-docs" do
  echo_system("rm -rf .yardoc doc/yard doc/rdoc doc/javascript doc/ri")
end
