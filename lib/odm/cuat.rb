# I thought I would need to have specific classes for each of the ODM
# tables to implement specific logic for each of the classes.  But it
# turns out that the Ruby part does not post process the parsed output
# so these classes are not used.
class CuAt < Odm::Base
end
