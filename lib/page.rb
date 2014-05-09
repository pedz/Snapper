require 'pathname'

# Routines that produce the html page.
module Page
  StylesheetDir = File.expand_path("../stylesheets", __FILE__)
  JavascriptDir = File.expand_path("../javascript", __FILE__)

  def create_page(db, outfile = $stdout)
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
    add_data(db)

    @outfile.puts <<'EOF'
  </head>
  <body>
    <svg class="chart">
    </svg>
  </body>
</html>
EOF
  end

  def include_stylesheets
    Pathname.new(StylesheetDir).find do |path|
      next unless path.file?
      @outfile.puts "    <style>"
      @outfile.puts path.read
      @outfile.puts "    </style>"
    end
  end

  def include_javascript
    # <script src="http://d3js.org/d3.v3.min.js"></script>
    # <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    @outfile.puts <<'EOF'
    <script src="http://d3js.org/d3.v3.js"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.js"></script>
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

  def add_data(db)
    logger.debug { "db KEYS" }
    logger.debug { db.keys.join("\n") }
    @outfile.puts "    <script>"
    @outfile.puts "        window.snapper.world.addSnap(";
    @outfile.puts JSON.pretty_generate(db)
    @outfile.puts "        );"
    @outfile.puts "    </script>"
  end
end
