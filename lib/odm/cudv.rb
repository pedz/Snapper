# I thought I would need to have specific classes for each of the ODM
# tables to implement specific logic for each of the classes.  But it
# turns out that the Ruby part does not post process the parsed output
# so these classes are not used.  The javascript does all the post
# parsing mastication.
class CuDv < Odm::Base
  def attributes(db)
    name = self.name
    pddvln = self.PdDvLn
    attrs = {}
    predefined = db.table('PdAt').find_all { |pdat|
      pdat.uniquetype == pddvln
    }.each { |pdat|
      attrs[pdat.attribute] = pdat.deflt
    }
    db.table('CuAt').find_all { |cuat|
      cuat.name == name
    }.each { |cuat|
      attrs[cuat.attribute] = cuat.value
    }
    Odm::Base.new(attrs)
  end
end
