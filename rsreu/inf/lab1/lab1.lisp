

(ql:quickload "qt")

(defpackage :information-theory-lab1
  (:use :cl :qt)
  (:export :main))

(in-package :information-theory-lab1)
(named-readtables:in-readtable :qt)

(qt:ensure-smoke "qtuitools")


(defun find-child (object name)
  (let ((children (#_children object)))
    (or
     (loop for child in children
           when (equal name (#_objectName child))
           return child)
     (loop for child in children
           thereis (find-child child name)))))

(defun find-value (object name)
  (#_value (find-child object name)))
(defun find-value-set (object name value)
  (#_setValue (find-child object name) value))
(defsetf find-value find-value-set)

(defun find-text (object name)
  (#_text (find-child object name)))
(defun find-text-set (object name txt)
  (#_setText  (find-child object name)
              (cond ((stringp txt) txt)
                    ((integerp txt) (write-to-string txt))
                    ((floatp txt) (format nil "~,6f" txt))
                    (t (format nil "~a" txt)))))
(defsetf find-text find-text-set)


(defclass my-window ()
  ((plotView :accessor plotView))
  (:metaclass qt-class)
  (:qt-superclass "QWidget")
  (:slots ("calculate()" calculate)))

(defmethod initialize-instance :after ((win my-window) &key)
  (new win)
  (let* ((loader (#_new QUiLoader))
         (file   (#_new QFile "lab1.ui"))
         (layout (#_new QHBoxLayout win))
         (widget (#_load loader file)))
    (#_addWidget layout widget))
  (#_setWindowTitle win "Л.р. №1. Анализ статистических свойств и моделирование источников сообщений. Гейнц Р.А. 243")
  (let ((btn (find-child win "calculate")))
    (connect btn "clicked()" win "calculate()"))
  (let* ((view  (find-child win "plotView"))
         (scene (#_new QGraphicsScene view)))
    (#_setScene view scene)
    (setf (plotView win) view)))


(defun generate (n b c)
  (labels ((weibull (uniform) (* b (expt (- (log uniform)) (/ 1 c)))))
    (let ((*random-state* (make-random-state t)))
      (let ((arr (make-array n)))
        (loop for i upto (- n 1) do (setf (aref arr i) (weibull (random 1.0))))
        arr))))

(defun make-weibull-density-function (b c)
  #'(lambda (x) (/ (* c (expt c (- x 1)) (exp (- (expt (/ x b) c)))) (expt b c))))

(defun minimum (arr) (reduce #'min arr))
(defun maximum (arr) (reduce #'max arr))
(defun sum     (arr) (reduce #'+   arr))
(defun expectation (arr) (/ (sum arr) (length arr)))
(defun variance (arr expectation)
  (labels ((square (x) (expt x 2))
           (center (x) (- x expectation)))
    (loop for i upto (- (length arr) 1)
      summing (square (center (aref arr i))) into sum
      summing 1 into length
      finally (return (/ sum length)))))
(defun std-deviation (variance) (sqrt variance))


(defmethod plot ((win my-window) length minimum maximum rndlst
                 density expectation deviation)
  (let* ((view  (plotView win))
         (scene (#_scene view)))
    (let* ((intervals (+ 1 (floor (+ .5 (log length 2)))))
           (interval-size (/ (- maximum minimum) intervals))
           (buckets (make-array intervals :initial-element 0))
           (points (* 10 intervals))
           (step (/ (- maximum minimum) (* 10 intervals)))
           (density-x (make-array points :initial-element 0))
           (density-y (make-array points :initial-element 0)))
      ; fill buckets
      (loop for i upto (- length 1)
        do (let* ((x (aref rndlst i))
                  (j (min (floor (/ (- x minimum) interval-size))
                          (- intervals 1))))
              (incf (aref buckets j) x)))
      ; tabulate density
      (loop for i upto (- points 1)
        do (let* ((x (+ minimum (* i step)))
                  (y (funcall density x)))
              (setf (aref density-x i) x)
              (setf (aref density-y i) y)))
      (let* ((palette (#_palette view))
             (text-color (#_color (#_text palette)))
             (foreground-pen (#_new QPen text-color))
             (foreground-brush (#_new QBrush text-color))
             (base-color (#_color (#_base palette)))
             (base-pen (#_new QPen base-color))
             (base-dash-pen (#_new QPen base-color))
             (base-brush (#_new QBrush base-color))
             (highlight-color (#_color (#_highlight palette)))
             (highlight-pen (#_new QPen highlight-color))

             (maxb (maximum buckets))
             (xdelta (- maximum minimum))

             (w 800) (xf (/ w xdelta)) (xunit 10)
             (h 600) (yf (/ h maxb)) (yunit 10)

             (maxdensity (maximum density-y))
             (densityf (/ h maxdensity)))
        (#_setStyle base-dash-pen (#_Qt::DashLine))
        (#_clear scene)
        ; draw bar-chart
        (loop for i upto (- intervals 1)
          do (let ((bucket (aref buckets i)))
                (#_addRect scene
                  (* xf i interval-size) (- h (* yf bucket))
                  (* xf interval-size) (* yf bucket)
                  base-pen foreground-brush)))
        ; draw density
        (loop for i from 1 to (- points 1)
          do (let ((x (aref density-x i))
                   (px (aref density-x (- i 1)))
                   (y (aref density-y i))
                   (py (aref density-y (- i 1))))
                (#_addLine scene
                  (* xf px) (- h (* densityf py))
                  (* xf x) (- h (* densityf y))
                  highlight-pen)))
        ; axis
        ; vertical
        (#_addLine scene
          (- xunit) (+ h yunit)
          (- xunit) (- yunit) foreground-pen)
        ; horizontal
        (#_addLine scene
          (- (* 2 xunit)) h
          (+ w xunit) h foreground-pen)
        ; x-axis marks
        (labels ((xmark (fmt x)
                    (let* ((scaled (* xf (- x minimum))))
                      (#_addLine scene
                        scaled (- h (/ yunit 2))
                        scaled (+ h (/ yunit 2)) foreground-pen)
                      (let ((txt (#_addText scene (format nil fmt x))))
                        (#_setPos txt scaled h)))))
          (xmark "x_min~%~,2f" minimum)
          (xmark "x_max~%~,2f" maximum)
          (xmark "M(x)~%~,2f" expectation)
          (xmark "M(x) - σ(x)~%~,2f" (- expectation deviation))
          (xmark "M(x) + σ(x)~%~,2f" (+ expectation deviation)))))
    (#_show view)
    (#_fitInView view (#_itemsBoundingRect scene) (#_Qt::KeepAspectRatio))))


(defmethod calculate ((win my-window))
  (let* ((n      (max 2     (find-value win "samplesCount")))
         (b      (max 0.001 (find-value win "parameterB")))
         (c      (max 0.001 (find-value win "parameterC")))

         (rndlst (generate n b c))

         (minimum (minimum rndlst))
         (maximum (maximum rndlst))
         (expectation (expectation rndlst))
         (variance (variance rndlst expectation))
         (deviation (std-deviation variance)))
    (setf (find-text win "minValue") minimum)
    (setf (find-text win "maxValue") maximum)
    (setf (find-text win "expectation") expectation)
    (setf (find-text win "variance") variance)
    (setf (find-text win "standartDeviation") deviation)
    (plot win (length rndlst) minimum maximum rndlst
          (make-weibull-density-function b c) expectation deviation)))


(defun main ()
  (with-main-window (win (make-instance 'my-window))
    (calculate win)))

(main)
