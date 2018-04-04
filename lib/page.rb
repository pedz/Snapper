require_relative 'logging'
require 'pathname'

# class that produces the html page.
class Page
  # Directory where the css stylesheets live.
  StylesheetDir = File.expand_path("../stylesheets", __FILE__)

  # Directory where the javascript lives.
  JavascriptDir = File.expand_path("../javascript", __FILE__)

  # @param batch [Batch] The batch produced by the current run.
  # @param outfile [File] The file to write the HTML to.
  # @param one_file [Boolean] If true, then add the javascript code
  #   and stylesheets inline with the HTML.  If false, pull them in
  #   via the appropiate link or script tags.
  def initialize(batch, outfile = $stdout, one_file = true)
    @batch = batch
    @outfile = outfile
    @one_file = one_file
  end

  # Creates the HTML page.
  def create_page
    @outfile.puts <<'EOF'
<!DOCTYPE html>
<html>
  <head>
    <title>Fun Fun Fun</title>
    <meta charset="utf-8">
EOF

    include_stylesheets
    include_javascript
    add_data(@batch)
    @outfile.puts <<'EOF'
  </head>
  <body>
    <svg class="chart">
    </svg>
  </body>
</html>
EOF
    @outfile.flush
  end

  private

  # method to add the stylesheets found in lib/stylesheets into the
  # HTML page.  These are currently copied into the output file.
  def include_stylesheets
    Pathname.new(StylesheetDir).find do |path|
      next unless path.file?
      if @one_file
        @outfile.puts "    <style>"
        @outfile.puts path.read
        @outfile.puts "    </style>"
      else
        @outfile.puts "<link href=\"lib/stylesheets/#{path.basename}\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
      end
    end
  end

  # Adds what is necessary to load in all of the javascript
  # libraries which include jQuery plus those found in
  # lib/javascript.
  def include_javascript
    @outfile.puts <<'EOF'
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.js"></script>
    <link rel="stylesheet" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/themes/smoothness/jquery-ui.css" />
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/jquery-ui.min.js"></script> 
EOF
    Pathname.new(JavascriptDir).find do |path|
      next unless path.file?
      if @one_file
        @outfile.puts "    <script>"
        @outfile.puts path.read
        @outfile.puts "    </script>"
      else
        @outfile.puts "<script src=\"lib/javascript/#{path.basename}\"></script>"
      end
    end
  end

  # Adds in the call to addSnap and the json representation of db into
  # the html page.  Produces a script tag which calls
  # {window.snapper.world.addBatch}[../javascript/Snapper-World.html#addBatch]
  # passing it the JSON output of batch.
  def add_data(batch)
    @outfile.puts "    <script>"
    @outfile.puts "        window.snapper.world.addBatch(";
    @outfile.puts JSON.pretty_generate(batch)
    @outfile.puts "        );"
    @outfile.puts "    </script>"
  end
end
