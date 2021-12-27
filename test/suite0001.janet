(import ./../jalmer :as j)
(import ./helper :prefix "")

(let [template-fn (j/make-template-fn "test/resources/index.html")]
  (is (str= (template-fn {:items [300 400 500]})
            "<html>\n  <head>\n    <header-entry from=\"_base.html\"/>\n    \n<header-entry from=\"index.html\">\n  </head>\n  <body>\n    <h1>Header from _base</h1>\n    \n<h2>Main content</h2>\n<ul>\n\n<li>Item: 300 for_index: 0</li>\n\n\n<li>Item: 400 for_index: 1</li>\n\n\n<li>Item: 500 for_index: 2</li>\n\n\n</ul>\n  </body>\n</html>\n")))
