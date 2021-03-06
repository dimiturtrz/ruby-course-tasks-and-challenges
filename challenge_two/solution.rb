SINGLE_BUTTONS = ['1','*','#',' ']
FIRST_LETTERS = ['A', 'D', 'G', 'J', 'M', 'P', 'T', 'W']
def button_presses(message)
  total = 0
  message.upcase.each_char do |char|
    case char
      when *SINGLE_BUTTONS then total += 1
      when '0'             then total += 2
      when '1'..'9'        then total += (['7','9'].include? char)? 5 : 4
      when 'A'..'Z'        then total += 
        char.ord - FIRST_LETTERS.select{|num| num.ord < char.ord+1}.max.ord + 1
    end
  end
  total
end
