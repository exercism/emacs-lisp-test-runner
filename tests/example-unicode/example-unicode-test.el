;;; example-unicode-test.el --- Parallel Letter Frequency (exercism)  -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:


(load-file "example-unicode.el")
(declare-function calculate-frequencies "example-unicode.el" (texts))


(defun hash-table-contains (expected actual)
  (let ((result t))
    (maphash (lambda (key value)
               (unless (equal (gethash key actual) value)
                 (setq result nil)))
             expected)
    result))


(ert-deftest unicode-letters ()
  (let ((expected (make-hash-table :test 'equal)))
    (puthash ?ø 1 expected)
    (puthash ?φ 1 expected)
    (puthash ?ほ 1 expected)
    (puthash ?本 1 expected)
    (should (hash-table-contains expected (calculate-frequencies '("ø" "φ" "ほ" "本"))))))


(provide 'example-unicode-test)
;;; example-unicode-test.el ends here
