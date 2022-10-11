;;; leap.el --- Leap exercise (exercism)  -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(defun leap-year-p (year)
  "Determine if YEAR is a leap year."
  (print (format "Hello from stdout. It is %s now" year))
  ; 'message' writes to the stderr in batch mode
  (message "Hello from stderr")
  (print "       (__)
 `------(oo)
  ||    (__)
  ||w--||")
  (print
   "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris sit amet tellus lectus. Suspendisse dignissim molestie sagittis. Praesent egestas massa a est maximus iaculis. Morbi varius nulla in purus hendrerit, eget tincidunt diam malesuada. Morbi convallis non ex eget auctor. Aenean massa tellus, maximus a fermentum non, tempor quis sem. Integer finibus tincidunt convallis. Curabitur dapibus lorem vitae nunc luctus pretium. Proin at efficitur elit, in eleifend ligula. Aenean dapibus mattis augue, vel consectetur lorem.")
  (and (= 0 (mod year 4))
       (or (not (= 0 (mod year 100)))
           (= 0 (mod year 400)))))

(provide 'leap)
;;; leap.el ends here
