require 'jasmine'
load 'jasmine/tasks/jasmine.rake'

desc "Make the jsdoc3 documentation for the javascript"
task :jsdoc do
  system "jsdoc --configure doc/conf.json"
end

desc "Make the rdoc documentation"
task :rdoc do
  exclude = %w{
		Gemfile
		Gemfile\.lock
		Rakefile
		\.bundle
		\.git
		doc/conf\.json
		doc/javascript
		doc/ruby
		features
		lib/javascript
		lib/stylesheets
		spec
		temp
		test\.snap
  		.*\.html
                .*\.jpg
	      }
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

  system [ "echo rdoc",
           "'--all'",
           "'--main=README'",
           "'--exclude=\\./(#{exclude.join('|')})'",
           "'--output=doc/ruby'" ].join(' ')
  system [ "rdoc",
           "'--all'",
           "'--main=README'",
           "'--exclude=\\./(#{exclude.join('|')})'",
           "'--output=doc/ruby'" ].join(' ')
end
