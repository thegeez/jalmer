
(defn str= [l r]
  (if (buffer? l)
    (= (string l)
       r)
    (= l r)))

(defmacro is [form]
  (when (not= (type form) :tuple)
    (error "is test form needs a tuple as argument"))
  (let [[comp-op actual expected] form]
    (when (not (or (= comp-op '=)
                   (= comp-op 'str=)
                   (= comp-op 'err=)))
      (errorf "comp-op must be =/str=/err=, got %p" comp-op))
    (if (= comp-op 'err=)
      (tuple 'let (tuple (tuple/brackets 'result-type 'result) (tuple 'try (tuple/brackets :non-error actual)
                                                                       (tuple (tuple 'err) (tuple/brackets :error (tuple 'string 'err))))
                         'exp expected)
              (tuple 'if (tuple '= 'result-type :non-error)
                      (tuple 'errorf "Test failed: \nactual non-error:   %p\nexpected error:  %p" 'result 'exp)
                      (tuple 'if (tuple '= 'result 'exp)
                              nil
                              (tuple 'errorf "Test failed: \nactual error:   %p\nexpected error: %p" 'result 'exp))))

      # = / str=
      (tuple 'let (tuple 'result actual 'exp expected)
              (tuple 'if (tuple comp-op 'result 'exp)
                      nil
                      (tuple 'errorf "Test failed: \nactual:   %p\nexpected:  %p" 'result 'exp))))))
