;;;;;; yaml-expr.rkt - YAML expressions.    -*- Mode: Racket -*-

#lang racket

(require racket/generic "nodes.rkt")

(provide
 node?
 (contract-out
  (struct typeable
    ([type? (any/c . -> . boolean?)]))
  (struct (yaml-constructor typeable)
    ([type? (any/c . -> . boolean?)]
     [tag string?]
     [construct (node? . -> . yaml?)]))
  (struct (yaml-multi-constructor typeable)
    ([type? (any/c . -> . boolean?)]
     [tag-prefix string?]
     [construct (string? node? . -> . yaml?)]))
  (struct (yaml-representer typeable)
    ([type? (any/c . -> . boolean?)]
     [represent (any/c . -> . node?)]))
  [yaml? (any/c . -> . boolean?)]
  [yaml-null (parameter/c any/c)]
  [yaml-null? (any/c . -> . boolean?)]
  [yaml-constructors
   (parameter/c (listof (or/c yaml-constructor? yaml-multi-constructor?)))]
  [yaml-representers (parameter/c (listof yaml-representer?))]))

(module+ test (require rackunit racket/date))

(define yaml-null (make-parameter 'null))

(define (yaml-null? v)
  (equal? v (yaml-null)))

(struct typeable (type?))

(struct yaml-constructor typeable (tag construct))
(struct yaml-multi-constructor typeable (tag-prefix construct))
(define yaml-constructors (make-parameter '()))

(struct yaml-representer typeable (represent))
(define yaml-representers (make-parameter '()))

(define (yaml-types)
  (remove-duplicates
   (map typeable-type?
        (append (yaml-constructors)
                (yaml-representers)))))

(define (yaml? v)
  (or (yaml-null? v)
      (string? v)
      (symbol? v)
      (bytes? v)
      (boolean? v)
      (exact-integer? v)
      (inexact-real? v)
      (date? v)
      (and (list? v)
           (andmap yaml? v))
      (and (hash? v)
           (for/and ([(key val) v])
             (and (yaml? key)
                  (yaml? val))))
      (and (set? v)
           (for/and ([val v])
             (yaml? val)))
      (and (vector? v)
           (for/and ([val v])
             (yaml? val)))
      (and (pair? v)
           (yaml? (car v))
           (yaml? (cdr v)))
      (for/or ([type? (yaml-types)])
        (type? v))))

(module+ test
  (test-case "yaml?"
    (define exprs
      (list (yaml-null) "string" #t 1 1.0 (current-date) #"bytes"))
    (check-true (yaml? '()))
    (check-true (yaml? (set)))
    (check-true (yaml? exprs))
    (check-true (yaml? (set exprs)))
    (check-true (yaml? (cons "first" "second")))
    (check-true (yaml? (make-hash)))
    (check-true (yaml? #hash(("key" . "value"))))
    (check-true (yaml? 'yaml?))
    (check-true (yaml? #(1 2 3))))

  (test-case "yaml-null?"
    (check-true (yaml-null? (yaml-null)))
    (check-false (yaml-null? 'foo))
    (parameterize ([yaml-null 'foo])
      (check-true (yaml-null? 'foo)))))
