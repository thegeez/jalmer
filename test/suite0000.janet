(import ./../jalmer :as j)
(import ./helper :prefix "")

(is (str= (j/render "{% if (= (get args :username) \"bob\") %} hi {% else %} lol {% endif %}")
          " lol "))
(is (str= (j/render "{% if (= (getx args :username) \"bob\") %} hi {% else %} lol {% endif %}" {:username "bob"})
          " hi "))

(is (str= (j/render "before {% if true %} hi {% if true %}!{% else %}?{% endif %}{% else %} lol {% endif %}after")
          "before  hi !after"))

(is (str= (j/render "12{{345}}678")
          "12345678"))

(is (str= (j/render "12{% if true %}3{{345}}45{% endif %}67")
          "1233454567"))

(is (str= (j/render "Hello {{(getx args :name)}}" {:name "Your name"})
          "Hello Your name"))

(is (err= (j/render "Hello {{(getx args :username)}}" {})
          "getx failed for key: :username"))

(is (str= (j/render "{{(getx args :name)}} lol {# hi #} Hahaha" {:name "Your name"})
          "Your name lol  Hahaha"))

(is (str= (j/render "<ul>
{% for item in (getx args :items) %}
<li>{{item}}</li>
{% endfor %}
</ul>" {:items [1 2 3]})
"<ul><li>1</li><li>2</li><li>3</li></ul>"))

(is (str= (j/render "<ul>
{% for item in (getx args :items) %}
{- (def item (get item :a)) -}
<li>{{item}} index {{ for_index }}</li>
{% endfor %}
</ul>" {:items [{:a 40} {:a "<h1>50</h1>"} {:a 60}]})
"<ul><li>40 index 0</li><li>&lt;h1&gt;50&lt;/h1&gt; index 1</li><li>60 index 2</li></ul>"))


(is (str= (j/render "Hello this is a scope
{% do %}
{- (def item \"some <b>string</b>\") -}
<h1>{{item}}</h1>
{% enddo %}
item not def'd here" {})
"Hello this is a scope<h1>some &lt;b&gt;string&lt;/b&gt;</h1>item not def'd here"))

(is (str= (j/render "{- (var i 1) (++ i) -}i is: {{i}}")
          "i is: 2"))

