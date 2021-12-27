(import ./../jalmer :as j)
(import ./helper :prefix "")

(is (err= (j/render `Some
lines
before
the tag {{ (code lacks end paren }}`)
          "Code parsing error at line: 4 column: 11 code: \" (code lacks end paren \"\n
 with parse error: \"unexpected end of source, ( opened at line 1, column 1\""
          ))

(is (err= (j/render `Some
lines
before
the tag{{ (code) }}`)
          "Error on compile: @{:column 11 :error \"unknown symbol code\" :line 1}"
          )) # todo propagate proper location of error in template

(is (err= (j/render "{% include \"somefile.html\" %}")
          "could not open file somefile.html"))

(is (err= (j/render "{% include \"somefile.html %}")
          "Missing ending \" at line: 1 column: 29"))

(is (err= (j/render "{% include somefile.html\" %}")
          "Missing opening \" at line: 1 column: 12"))

(is (err= (j/render "{% include \"somefile.html\"")
          "Missing space at line: 1 column: 27"))

(is (err= (j/render "{% include \"somefile.html\" ")
          "Missing ending %} at line: 1 column: 28"))

(is (err= (j/render "{% if (zero? (- a b)) %}Zero{% else %}Not zero")
          "If not closed at line: 1 column: 29"))

(is (err= (j/render "Some things before\n
{% if true Zero{% else %}Not zero{% endif %}")
          "Code parsing error at line: 2 column: 7 code: \"true Zero{% else\"\n with parse error: \"parser has unchecked error, cannot consume\""))

(is (err= (j/render "Some things before\n
{% if (and some thing) %}Zero{% else Not zero{% endif %}")
          "Missing ending %} at line: 2 column: 38"))

(is (err= (j/render "Some things before\n
{% if (and some thing) %}Zero{% else %}Not zero{% endif ")
          "Missing ending %} at line: 2 column: 57"))

(is (err= (j/render "Some things before\n
{% if (and some thing) %}Zero{% else %}Not zero")
          "If not closed at line: 2 column: 30"))

(is (err= (j/render "Some things before\n
{% for item (and some thing) %}Loop body with in {% endfor %}")
          "Missing 'in' in 'for <binding> in <code>' at line: 2 column: 30"))

(is (err= (j/render "Some things before\n
{% for item in lol Loop body with{% endfor %}
Some stuff after")
          "Missing endfor tag at line: 2 column: 62")) # actual error should be missing %} at for

(is (err= (j/render "Some things before\n
{% for item in lol %}Loop body with
Some stuff after")
          "Missing endfor tag at line: 2 column: 52"))

(is (err= (j/render "Some things before\n
{% for item in lol %}Loop body with{% endfor
Some stuff after")
          "Missing space at line: 2 column: 45"))

