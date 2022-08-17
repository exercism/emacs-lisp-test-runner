;;; leap-test.el --- Tests for Leap exercise (exercism)

;;; Commentary:

;;; Code:
(load-file "example-commented.el")

(ert-deftest vanilla-leap-year ()
  (should (leap-year-p 1996)))

;; (ert-deftest exceptional-century ()
;;   (should (leap-year-p 2000)))

(provide 'leap-test)
;;; leap-test.el ends here
