require 'jasmine'
load 'jasmine/tasks/jasmine.rake'

desc "Make the jsdoc3 documentation for the javascript"
task :jsdoc do
  system "jsdoc --configure doc/conf.json"
end

desc "Make the rdoc documentation"
task :rdoc do
  exclude = %w{
  		.*\.html
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
	      }
  system [ "echo rdoc",
           "'--all'",
           "'--exclude=\\./(#{exclude.join('|')})'",
           "'--output=doc/ruby'" ].join(' ')
  system [ "rdoc",
           "'--all'",
           "'--exclude=\\./(#{exclude.join('|')})'",
           "'--output=doc/ruby'" ].join(' ')
end
