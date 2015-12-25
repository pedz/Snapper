require 'stringio'
require 'odm'

# class CuDv
#   def initialize(text, hash)
#     @hash = hash
#   end
# end

Given(/^an CuDv file$/) do
  @file = StringIO.new <<'HERE'

CuDv:
	name = "sys0"
	status = 1
	chgstatus = 1
	ddins = "planar_pal_chrp"
	location = ""
	parent = ""
	connwhere = ""
	PdDvLn = "sys/node/chrp"

CuDv:
	name = "sysplanar0"
	status = 1
	chgstatus = 2
	ddins = ""
	location = ""
	parent = "sys0"
	connwhere = "0"
	PdDvLn = "planar/sys/sysplanar_rspc"
HERE
end

Given(/^a db instance$/) do
  @db = Db.new
end

When(/^fed to the parser$/) do
  Odm.new(@file, @db).parse
end

Then(/^its entries will be available\.$/) do
  expect(@db.cu_dv.length).to eq(2)
end
