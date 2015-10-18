(car (quote (Hello_World 123 456)))

(de f (n)
  (cond ((eq n 0) 1)
        (T (* n (f (1- n))))
  )
)

(f 5)
(f 6)
(f 7)

(de map (f xs)
   (cond ((atom xs) xs)
         (T (cons (f (car xs)) (map f (cdr xs))))
   )
)

(de ap (xs ys)
   (cond ((atom xs) ys)
         (T (cons (car xs) (ap (cdr xs) ys)))
   )
)

(de try (f n)
  (cond ((zerop n) (list (f 0)))
        (T (cons (f n) (try f (1- n))))
  )
)

(de ints (i j)
  (cond ((> i j) nil)
        (T (cons i (ints (1+ i) j)))
  )
)

(de void (x) nil)

(de pr (x) (void (list (print x) (terpri) (terpri)))
)

(de junk (n)
  (pr (map 1+ (ints 1 n)))
)

(de len (xs)
  (cond ((atom xs) 0) (T (1+ (len (cdr xs)))))
)

(len '(1 2 3 4 5))

(ints 1 10)
(map 1+ (ints 1 10))
(car (map 1+ (ints 1 10)))


(try junk 25)

(ints 50 100)

(try 1+ 10)

(ap '(10 20 30 40 50) '(1 2 3 4 5))

(map 1+ ())

(cons 1 '(2 3))

(map 1+ '(10 20 30 40 50))
 
(quit)
