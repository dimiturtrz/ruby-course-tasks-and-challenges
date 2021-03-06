def complement(f)
  ->(*args) { !f.call(*args) }
end

def compose(f, g)
  ->(*args) { f.call(g.call(*args)) }
end
