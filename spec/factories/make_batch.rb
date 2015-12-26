require 'batch'
require 'snap'
require 'date'
require 'time'

def fake_batch(options = {})
  snaps = options[:snaps].map { |snap| fake_snap(snap) }
  Batch.new(snaps)
end

def adjust_object(obj, list)
  list.each do |method, result, proc|
    if obj.respond_to?(method) && (obj.send(method) == result)
      proc.call(obj)
    end
  end
end

def adjust_item(item, list)
  adjust_object(item, list)
  item.each_pair do |k, v|
    adjust_item(v, list) if v.is_a?(Item)
  end
end

def adjust_batch(batch, list)
  batch.each_cec do |cec|
    adjust_object(cec, list)
    cec.each_lpar do |lpar|
      adjust_object(lpar, list)
      lpar.each_snap do |snap|
        adjust_object(snap, list)
        adjust_item(snap.db, list)
      end
    end
  end
  batch
end

def expect_no_alerts(batch)
  expect(batch).not_to receive(:add_alert)
  batch.each_cec do |cec|
    expect(cec).not_to receive(:add_alert)
    cec.each_lpar do |lpar|
      expect(lpar).not_to receive(:add_alert)
      lpar.each_snap do |snap|
        expect(snap).not_to receive(:add_alert)
      end
    end
  end
  batch
end

def fake_snap(options = {})
  dir = (options[:dir] || "none")
  db = Db.new

  options[:db].each_pair do |k, v|
    v = [ v ] unless v.is_a?(Array)
    v.each do |f|
      item = db.create_item(k.to_s)
      fake_item(item, f, db)
    end
  end
  db.date_time = DateTime.parse(options[:date_time]) if options.has_key?(:date_time)

  Snap.new(db: db, dir: dir )
end

def fake_item(item, attrs, db)
  attrs.each_pair do |k, v|
    if v.is_a?(Hash)
      item[k] = fake_item(Item.new(db), v, db)
    elsif v.is_a?(Array)
      item[k] = v.map { |h| fake_item(Item.new(db), h, db) }
    else
      item[k] = v
    end
  end
  item
end

def fake_attr(value)
  { value: value }
end
