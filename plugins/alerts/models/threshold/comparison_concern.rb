module Threshold::ComparisonConcern
  extend ActiveSupport::Concern

  def eq(a, b)
    a == b
  end

  # eqi - equal ignore case operator
  def eqi(a, b)
    if a.class == String and b.class == String
      a.casecmp(b) == 0
    elsif a.class == Fixnum and b.class == Fixnum
      a == b
    elsif a.class == String and b.class == Array
      b.include? a
    else
      a.to_s.casecmp(b.to_s) == 0
    end
  end

  def lt(a, b)
    a < b
  end

  def lte(a, b)
    a <= b
  end

  def gt(a, b)
    a > b
  end

  def gte(a, b)
    a >= b
  end

  def con(a, b)
    not a.scan(/#{b}/i).empty?
  end

  def under(a, b)
    true if b.index a
  end
end
