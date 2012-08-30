require 'diff/lcs'
require 'diff/lcs/string'

a = "Hello world!"
patch1 = a.split("\n").diff("Good bye good world!".split("\n"))