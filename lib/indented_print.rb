def indented_print(array, d = 0)
  array.each do |elem|
    if elem.is_a?(String)
      $stdout << (" " * d) << elem << "\n"
    else
      indented_print(elem, d + 1)
    end
  end
end
