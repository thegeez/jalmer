## Jalmer

Template library for [Janet][janetlang]. Mix of [Selmer][selmer] and [Temple][temple].


[janetlang]: https://janet-lang.org
[selmer]: https://github.com/yogthos/Selmer
[temple]: https://git.sr.ht/~bakpakin/temple


## Usage
```
(import jalmer :as j)

(def index-template (j/make-template-fn "path/to/index.html"))

(def filled-template (index-template {:arguments "go here"}))
```

## Tags in template
- Code
```
(render "Name: {{ (getx args :name) }}" {:name "Your name"})
=> @"Name: Your name"
```
Function `getx` is as `get` but throws an error if the value is nil. There's also `get-inx`.

- If
```
(render "Hello {% if (= (getx args :username) \"bob\") %}Bob!{% else %}somebody else{% endif %}" {:username "bob"})
=> @"Hello Bob!"
```

- For
```
(render "<ul>
{% for item in (getx args :items) %}
<li>{{item}}</li>
{% endfor %}
</ul>" {:items [1 2 3]})
=> @"<ul><li>1</li><li>2</li><li>3</li></ul>"
```
Within a `for` loop `for_index` is the iteration index.

- Code (without text output)
```
{- (def item \"some <b>string</b>\") -}
```

- Comments
```
{# ... #}
```

- Larger example
```
(render "<ul>
{% for item in (getx args :items) %}
{- (def item (get item :a)) -}
{# ignored comment #}
<li>{{item}} index {{ for_index }}</li>
{% endfor %}
</ul>" {:items [{:a 40} {:a "<h1>50</h1>"} {:a 60}]})
=>
"<ul><li>40 index 0</li><li>&lt;h1&gt;50&lt;/h1&gt; index 1</li><li>60 index 2</li></ul>"
```

## Extending / including templates
```
{% extends "path/to/file.html" %}
{% block BLOCK_NAME %}{% endblock %}
{% include "path/to/file.html" %}```
See the example in `test/suite0001.janet` and the files in `test/resources`
```

## Development reloading
Templates are parsed once at load (or compile) time. To have templates reload on every call to a template function set environment variable `JANET_DEV_ENV` to something.
