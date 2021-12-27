(def- escape-peg
  (peg/compile
   ~(% (any (+ (* "&" (constant "&amp;"))
               (* "\"" (constant "&quot;"))
               (* "<" (constant "&lt;"))
               (* ">" (constant "&gt;"))
               (* "'" (constant "&#39;"))
               '1)))))

(defn escape-html [x]
  (in (peg/match escape-peg (string x)) 0))


(defn or-error [pat err-msg]
  ~(choice ,pat
            (error (replace (sequence (line) (column))
                            ,(fn [l c]
                               (string/format (string err-msg " at line: %p column: %p") l c))))))


(def grammar
  (peg/compile
   ~{:main (sequence :root
                     -1)
     :root (any (choice
                 :tagged
                 :keep-content))
     :keep-content
     (replace (capture (any (if-not (choice :tag-open :tag-close)
                              1)))
              ,(fn [c]
                 [:keep c]))

     :tag-open (choice :tag-open-inline
                       :tag-open-flow
                       :tag-open-code
                       :tag-open-comment)
     :tag-open-inline "{{"
     :tag-open-flow "{%"
     :tag-open-code "{-"
     :tag-open-comment "{#"
     :tag-close (choice :tag-close-inline
                        :tag-close-flow
                        :tag-close-code
                        :tag-close-comment)
     :tag-close-inline "}}"
     :tag-close-flow "%}"
     :tag-close-code "-}"
     :tag-close-comment "#}"
     :tag-close-inline-or-error ,(or-error :tag-close-inline-or-error
                                           "Missing ending }}")
     :tag-close-flow-or-error ,(or-error :tag-close-flow
                                         "Missing ending %%}")
     :tag-close-code-or-error ,(or-error :tag-close-code
                                         "Missing ending -}")
     :tag-close-comment-or-error ,(or-error :tag-close-comment
                                            "Missing ending -}")
     :space-or-error ,(or-error " " "Missing space")
     :tagged (choice :tagged-inline
                     :tagged-flow
                     :tagged-comment)
     :tagged-inline (replace (sequence :tag-open-inline
                                       (replace (sequence (line) (column) (capture (to :tag-close-inline)))
                                                ,(fn [line column code]
                                                   [:code code line column]))
                                       :tag-close-inline)
                             ,(fn [c]
                                [:inline c]))
     :tagged-comment (sequence :tag-open-comment
                               (drop :root)
                               :tag-close-comment)
     :tagged-flow (choice :tagged-if
                          :tagged-for
                          :tagged-include
                          :tagged-code
                          :tagged-do
                          :tagged-block
                          :tagged-extends
                          )
     :tagged-if (replace (capture (sequence :tag-open-flow " if "
                                            (replace (sequence (line) (column) (capture (to (sequence " " :tag-close-flow))))
                                                     ,(fn [line column code]
                                                        [:code code line column]))
                                            :space-or-error
                                            :tag-close-flow-or-error
                                            (replace (capture :root)
                                                     ,(fn [& c]
                                                        [:then (splice (array/slice c 0 -2))]))
                                            (choice (sequence :tag-open-flow " endif " :tag-close-flow-or-error)
                                                    (sequence :tag-open-flow " else " :tag-close-flow-or-error
                                                              (replace (capture :root)
                                                                       ,(fn [& c]
                                                                          [:else (splice (array/slice c 0 -2))]))
                                                              :tag-open-flow " endif " :tag-close-flow-or-error)
                                                    (error (replace (sequence (line) (column))
                                                                    ,(fn [l c]
                                                                       (string/format "If not closed at line: %p column: %p" l c)))))))
                         ,(fn [check then else &opt match]
                            (if match
                              [:if check then else]
                              [:if check then])))
     :tag-for-close (sequence :tag-open-flow " endfor"
                              :space-or-error
                              :tag-close-flow-or-error)
     :tagged-for (replace (capture (sequence :tag-open-flow " for "
                                             (replace (capture (choice (to (choice " in "
                                                                                   :tag-close-flow # needed to trigger missing in
                                                                                   -1 # needed to trigger missing in
                                                                                   ))
                                                                       ))
                                                      ,(fn [code]
                                                         [:for-bind code]))
                                             ,(or-error " in "
                                                        "Missing 'in' in 'for <binding> in <code>'")
                                             (replace (capture (to (sequence " " :tag-close-flow)))
                                                      ,(fn [code]
                                                         [:for-from code]))
                                             (sequence  :space-or-error :tag-close-flow-or-error
                                                (replace (capture :root)
                                                         ,(fn [& c]
                                                            [:body (splice (array/slice c 0 -2))]))
                                                ,(or-error :tag-for-close
                                                    "Missing endfor tag"))))
                          ,(fn [for-bind for-from body match]
                             [:for for-bind for-from body]))

     :quoted-file-path (sequence ,(or-error "\""
                                            "Missing opening \"")
                                  (replace (capture (some (if-not "\"" 1)))
                                           ,(fn [code]
                                              [:file-path code]))
                                  ,(or-error "\""
                                             "Missing ending \"")
                                  )
     :tagged-code (sequence :tag-open-code
                            (replace (capture (sequence (line) (column) (to (sequence " " :tag-close-code))))
                                     ,(fn [line column code]
                                        [:code code line column]))
                            :space-or-error
                            :tag-close-code-or-error
                            )
     :tagged-do (sequence :tag-open-flow " do " :tag-close-flow
                          (replace (capture :root)
                                   ,(fn [& c]
                                      [:body (splice (array/slice c 0 -2))]))
                          (sequence :tag-open-flow " enddo " :tag-close-flow-or-error))

     :tagged-block (replace (sequence :tag-open-flow " block "
                                      (replace (capture (to (sequence " " :tag-close-flow)))
                                               ,(fn [name]
                                                  [:block-name name]))
                                      :space-or-error :tag-close-flow-or-error
                                      (replace (capture :root)
                                               ,(fn [& c]
                                                  [:body (splice (array/slice c 0 -2))]))
                                      (sequence :tag-open-flow " endblock " :tag-close-flow-or-error (choice "\n" "")))
                            ,(fn [block-name body]
                               [:block block-name body]))
     :tagged-include (replace (sequence :tag-open-flow " include "
                                        :quoted-file-path
                                        :space-or-error
                                        :tag-close-flow-or-error
                                        )
                              ,(fn [[_file-path-kw file-path]]
                                 [:include file-path]))
     :tagged-extends (replace (sequence :tag-open-flow " extends "
                                        :quoted-file-path
                                        :space-or-error
                                        :tag-close-flow-or-error (choice "\n" "")
                                        )
                              ,(fn [[_file-path-kw file-path]]
                                 [:extends file-path]))
     }))

(defn str->ast [in]
  (peg/match grammar
             in))

(defn ast->code [form &opt blocks]
  (if (= (type form) :tuple)
    (let [op (get form 0)]
      (case op
        :keep (tuple 'do (splice (map (fn [line]
                                        (tuple 'buffer/push-string '__0b line)) (drop 1 form))))
        :code (try (parse (string "(upscope " (get form 1) ")"))
                   ([err fib]
                    (if (get form 2)
                      (let [line (get form 2)
                            column (get form 3)]
                        (errorf "Code parsing error at line: %p column: %p code: %p\n with parse error: %p" line column (get form 1) (string err)))
                      (propagate fib err))))
        :if (let [code (get form 1)
                  then (get form 2)]
              (if-let [else (get form 3)]
                (tuple 'if code then else)
                (tuple 'if code then)))
        :then (tuple 'do (splice (drop 1 form)))
        :else (tuple 'do (splice (drop 1 form)))
        :for (let [for-bind (get form 1)
                   for-from (get form 2)
                   body (get form 3)]
               (tuple 'do
                       (tuple 'var 'for_index 0)
                       (tuple 'loop [for-bind :in for-from]
                               body
                               (tuple '++ 'for_index))))
        :for-bind (symbol (get form 1))
        :for-from (parse (get form 1))
        :body (tuple 'do (splice (drop 1 form)))
        :inline (tuple 'buffer/push-string '__0b (tuple 'escape-html (get form 1)))
        :include2 (tuple 'do (splice (map (fn [line]
                                            (tuple 'buffer/push-string '__0b "%include%" line)) (drop 1 form))))
        :include (postwalk ast->code (str->ast (slurp (get form 1))))
        :extends (tuple :extends
                        (get form 1))
        :block (let [block-name (get form 1)]
                 (if blocks # doing ast->code for filling in an extends template
                   # include block in extends
                   (if-let [insert-block (get blocks block-name)]
                     (tuple 'do (splice insert-block))
                     nil # block in extendable template is not overwritten
                     )
                   # defining blocks to use in extends
                   (let [block-form (get form 2)]
                     (tuple :block
                            block-name
                            block-form))))
        :block-name (get form 1)

        (errorf "No ast clause for %p" form)))
    form))

(defn make-render [in &opt args]
  (def supplied (or args @{}))
  (let [ast (str->ast in)

        code (postwalk
              ast->code
              ast)

        _ (assert code "Could not parse template")

        code (if (= (-> code first first) :extends)
               (let [filename (get-in code [0 1])
                     in (slurp filename)
                     blocks (reduce
                              (fn [m block]
                                (put m (get block 1) (drop 2 block)))
                              @{}
                              (drop 1 code))
                     ast (str->ast in)
                     code (postwalk (fn [form]
                                      (ast->code form blocks)) ast)]
                 code)
               code)

        _ (assert (not= (-> code first first) :extends)
                  "Can't have nested :extends")

        code (tuple 'fn 'template-fn '[args]
                     (tuple 'let ['__0b (tuple 'buffer/new 1024)]
                             (splice code)))
        getx-fn (fn getx [ds k]
                  (or (get ds k)
                      (errorf "getx failed for key: %p" k)))
        get-inx-fn (fn get-inx [ds ks]
                  (or (get-in ds ks)
                      (errorf "get-inx failed for keys: %p" ks)))

        comp-env (table/setproto @{'getx @{:value getx-fn}
                                   'get-inx @{:value get-inx-fn}
                                   'escape-html @{:value escape-html}} (make-env))
        fn-asm (compile code comp-env)
        _ (when (get fn-asm :error)
            (errorf "Error on compile: %p" fn-asm)
            (printf "Error on compile %p" fn-asm)
            (printf "code %p" code))
        temple-fib (fiber/new fn-asm :e)
        _ (fiber/setenv temple-fib comp-env)
        template-fn (resume temple-fib)]
    template-fn
    ))

(defn render [in &opt args]
  (def supplied (or args @{}))
  (let [template-fn (make-render in)]
    (template-fn supplied)))


(defn make-template-fn [file-location]
  (if (os/getenv "JANET_DEV_ENV")
    (fn [args]
      (try (let [template-fn (-> file-location
                                 slurp
                                 make-render)
                ]
             (template-fn args))
           ([err]
            (string/format "TEMPLATE_ERROR %p %v" err err)
            )))
    ## normal case
    (let [template-fn (-> file-location
                          slurp
                          make-render)]
      # (fn [args] ... buffer out ...)
      template-fn)))
