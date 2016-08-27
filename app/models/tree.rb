class Tree < Struct.new(:text, :nodes)
  def self.new_from_hash(hash)
    name, children_hash = hash.first
    children = children_hash.map { |k, v| Tree.new_from_hash({k => v}) }
    if children.empty?
      children = nil
    end
    Tree.new(name, children)
  end

  def visit_all(&block)
    yield(self)
    children.each { |c| c.visit_all(&block) }
  end
end