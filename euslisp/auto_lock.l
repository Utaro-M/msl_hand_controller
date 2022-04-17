#!/usr/bin/env roseus
(load "package://msl_hand_controller/euslisp/msl-hand-interface.l")
(ros::load-ros-manifest "msl_hand_controller")
(ros::roseus "auto_lock")

(defclass auto-lock
  :super propertied-object
  :slots (hand current-over-array ref-angle-list)
  )

(defmethod auto-lock
  (:init (which-hand?)
         (setq hand which-hand?
               ref-angle-list (list 0.0 (* pi (/ 60 180.0)) (* pi (/ 90 180.0)) (* pi (/ 120 180.0)))
               index-lock-angle 0.0
               middle-lock-angle 0.0)
         (setq current-over-array (make-list 18 :initial-element 0)
               position-array (make-list 6 :initial-element 0)
               current-array (make-list 6 :initial-element 0)
               current-over-flag-array (make-list 6 :initial-element 0))

         (msl-hand-init)
         (ros::subscribe (format nil "~A_hand_controller/current_over_flag" hand) std_msgs::Bool  #'send self :call-back-flag)
         (ros::subscribe (format nil "~A_hand_controller/current_over_array" hand) std_msgs::Float32MultiArray  #'send self :call-back-array))
  (:call-back-flag(msg)
                  ;; (format t "call-back-flag")
                  (if (send msg :data)
                      (send self :lock-finger)))
  (:call-back-array(msg)
                   (setq current-over-array (send msg :data))
                   (setq  position-array (subseq current-over-array 0 6))
                   (setq  current-array (subseq current-over-array 6 12))
                   (setq  current-over-flag-array (subseq current-over-array 12))
                   ;; (format t "current-over-array:~A~%, position-array:~A~%, current-array:~A~%, current-over-flag-array:~A~%"
                   ;;         current-over-array position-array current-array current-over-flag-array)
                   )
  (:lock-finger()
               (if (equal hand "left")
                   (send *lhand-ri* :stop-motion)
                 (send *rhand-ri* :stop-motion))
               ;; (send (read-from-string (if (equal hand "left") (format nil "*lhand-ri*") (format nil "*rhand-ri*"))) :stop-motion)
               (if (elt current-over-flag-array 2);;index finger
                   (progn
                     (setq index-lock-angle (send self :nearest-angle (elt position-array 2) ref-angle-list))
                     (format t "index-lock-angle=~A~%" index-lock-angle)))
               (if (elt current-over-flag-array 4);;middle finger
                   (progn
                     (setq middle-lock-angle (send self :nearest-angle (elt position-array 4) ref-angle-list))
                     (format t "middle-lock-angle=~A~%" middle-lock-angle))))
  (:get-min(lis)
           (setq min-idx 0)
           (setq min-value (elt lis 0))
           (dotimes (i (length lis))
             (if (< (elt lis i) min-value)
                 (progn
                   (setq min-idx i)
                   (setq min-value (elt lis i)))))
           ;; (format t "(list min-idx min-value)=~A~%" (list min-idx min-value))
           (list min-idx min-value))
  ;; Output the angle closest to the presetnt-angle among the angles in the angle-list
  (:nearest-angle(present-angle angle-list)
                 (let ((diff-list (list 1000)))
                   (dotimes (i (length angle-list))
                     (list-insert (abs (- (elt angle-list i) (abs present-angle))) 100 diff-list))
                   ;; (format t "(cdr diff-list)=~A~%" (cdr diff-list))
                   (setq min-idx-value (send self :get-min (cdr diff-list)))
                   (elt angle-list (car min-idx-value))))
  )

(setq *ins-left* (instance auto-lock :init "left"))
(setq *ins-right* (instance auto-lock :init "right"))

(do-until-key
 (ros::spin-once)
)
