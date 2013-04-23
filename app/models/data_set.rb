class DataSet < ActiveRecord::Base
  attr_accessible :name, :md5
  has_many :samples

  def headers
    self.samples.map{|sample| sample.to_hash.keys}.flatten.uniq
  end
  def saved?
    if DataSet.find_by_md5(md5hexdigest)
      true
    else
      false
    end
  end
  def md5hexdigest
    key_value = self.samples.map{|sample| sample.key_value}.join
    Digest::MD5.hexdigest(key_value)
  end
  def to_csv(file_path)
    CSV.open(file_path, 'w') do |out|
      out << headers
      self.samples.each do |sample|
        out << headers.map{|header| sample.to_hash[header]}
      end
    end
  end
end
