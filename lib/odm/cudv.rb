
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
