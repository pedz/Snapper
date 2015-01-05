require_relative 'logging'
require 'pathname'

# Module that produces the html page.  This is currently loaded into
# Snapper.
module Page
  StylesheetDir = File.expand_path("../stylesheets", __FILE__)
  JavascriptDir = File.expand_path("../javascript", __FILE__)

  # Creates the HTML page sending it to outfile.  db_list is a list of
  # Db type items that have a to_json method.
  def create_page(db_list, outfile = $stdout)
    @outfile = outfile
    @outfile.puts <<'EOF'
<!DOCTYPE html>
<html>
  <head>
    <title>Fun Fun Fun</title>
    <meta charset="utf-8">
EOF

    include_stylesheets
    include_javascript
    db_list.each do |db|
      add_data(db)
    end
    @outfile.puts <<'EOF'
  </head>
  <body>
    <svg class="chart">
    </svg>
  </body>
</html>
EOF
  end

  private

  # method to add the stylesheets found in lib/stylesheets into the
  # HTML page.  These are currently copied into the output file.
  def include_stylesheets
    Pathname.new(StylesheetDir).find do |path|
      next unless path.file?
      @outfile.puts "<link href=\"lib/stylesheets/#{path.basename}\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
      # @outfile.puts "    <style>"
      # @outfile.puts path.read
      # @outfile.puts "    </style>"
    end
  end

  # Adds what is necessary to load in all of the javascript
  # libraries which include jQuery plus those found in
  # lib/javascript.  Currently all javascript files are referenced and
  # not copied into the HTML file.  I plan to have an option to go
  # either way.
  def include_javascript
    # <script src="http://d3js.org/d3.v3.min.js"></script>
    # <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    @outfile.puts <<'EOF'
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.js"></script>
    <link rel="stylesheet" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/themes/smoothness/jquery-ui.css" />
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/jquery-ui.min.js"></script> 
    <script>
      if (typeof window.snapper === "undefined") window.snapper = {};
    </script>
EOF
    Pathname.new(JavascriptDir).find do |path|
      next unless path.file?
      @outfile.puts "<script src=\"lib/javascript/#{path.basename}\"></script>"
      # @outfile.puts "    <script>"
      # @outfile.puts path.read
      # @outfile.puts "    </script>"
    end
  end

  # Adds in the call to addSnap and the json representation of db into
  # the html page.
  def add_data(db)
    @outfile.puts "    <script>"
    @outfile.puts "        window.snapper.world.addSnap(";
    @outfile.puts JSON.pretty_generate(db)
    @outfile.puts "        );"
    @outfile.puts "    </script>"
  end
end
