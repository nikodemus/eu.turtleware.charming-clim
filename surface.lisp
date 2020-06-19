(in-package #:eu.turtleware.charming-clim)

(defclass surface (buffer bbox)
  ((sink :initarg :sink :accessor sink :documentation "Flush destination")
   (row0 :initarg :row0 :accessor row0 :documentation "Scroll row offset")
   (col0 :initarg :col0 :accessor col0 :documentation "Scroll col offset"))
  (:default-initargs :row0 0 :col0 0))

(defmethod initialize-instance :after
    ((buf surface) &key data rows cols r1 c1 r2 c2)
  (destructuring-bind (d0 d1) (array-dimensions data)
    (unless rows
      (if (not (zerop d0))
          (setf rows d0)
          (setf rows (1+ (- r2 r1))))
      (setf (rows buf) rows))
    (unless cols
      (if (not (zerop d1))
          (setf cols d1)
          (setf cols (1+ (- c2 c1))))
      (setf (cols buf) cols)))
  (let ((clip (clip buf)))
    (setf (r2 clip) rows
          (c2 clip) cols))
  (adjust-array (data buf) (list rows cols) :initial-element nil))

(defmethod put-cell ((buf surface) row col ch fg bg)
  (let ((vrow (- (+ (r1 buf) row) (row0 buf) 1))
        (vcol (- (+ (c1 buf) col) (col0 buf) 1)))
    (when (and (<= (r1 buf) vrow (r2 buf))
               (<= (c1 buf) vcol (c2 buf)))
      (set-cell (sink buf) vrow vcol ch fg bg))))

(defmethod flush-buffer ((buffer surface) &rest args &key force)
  (declare (ignore args))
  (loop for row from 1 upto (rows buffer)
        do (loop for col from 1 upto (cols buffer)
                 for cell = (get-cell buffer row col)
                 when (or force (dirty-p cell))
                   do (put-cell buffer row col (ch cell) (fg cell) (bg cell))
                      (setf (dirty-p cell) nil))))

(defun move-to-row (buf row0)
  (let* ((rows (rows buf))
         (height (1+ (- (r2 buf) (r1 buf))))
         (vrow1 (- 1    row0))
         (vrow2 (- rows row0)))
    (when (if (> height rows)
              (and (<= 1 vrow1 height)
                   (<= 1 vrow2 height))
              (and (<= vrow1 1)
                   (>= vrow2 height)))
      (setf (row0 buf) row0))))

(defun move-to-col (buf col0)
  (let* ((cols (cols buf))
         (width (1+ (- (c2 buf) (c1 buf))))
         (vcol1 (- 1    col0))
         (vcol2 (- cols col0)))
    (when (if (> width cols)
              (and (<= 1 vcol1 width)
                   (<= 1 vcol2 width))
              (and (<= vcol1 1)
                   (>= vcol2 width)))
      (setf (col0 buf) col0))))

#+ (or) ;; naive version
(defun scroll-buffer (buf row-dx col-dx)
  (incf (row0 buf) row-dx)
  (incf (col0 buf) col-dx))

(defun scroll-buffer (buf row-dx col-dx)
  (flet ((quantity (screen-size buffer-size dx)
           (if (alexandria:xor (> screen-size buffer-size)
                               (minusp dx))
               0
               (- buffer-size screen-size))))
    (unless (zerop row-dx)
      (let ((height (1+ (- (r2 buf) (r1 buf)))))
        (or (move-to-row buf (+ (row0 buf) row-dx))
            (setf (row0 buf)
                  (quantity height (rows buf) row-dx)))))
    (unless (zerop col-dx)
      (let ((width (1+ (- (c2 buf) (c1 buf)))))
        (or (move-to-col buf (+ (col0 buf) col-dx))
            (setf (col0 buf)
                  (quantity width (cols buf) col-dx)))))))

(defun move-buffer (buf row-dx col-dx)
  (incf (r1 buf) row-dx)
  (incf (r2 buf) row-dx)
  (incf (c1 buf) col-dx)
  (incf (c2 buf) col-dx))
