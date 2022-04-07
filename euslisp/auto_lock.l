#!/usr/bin/env roseus
(load "package://msl_hand_controller/euslisp/msl-hand-interface.l")
(ros::load-ros-manifest "msl_hand_controller")
(ros::roseus "auto_lock")

;; current-over-count: Total number of exceeds for all fingers
(defclass auto-lock-one-hand
  :super propertied-object
  :slots (hand position-value current-value current-threshold ref-angle-list current-over-flag ref-name-list current-over-count)
  )
(defmethod auto-lock-one-hand
  (:init (which-hand? threshold data-name-list current-over-count-threshold)
         (setq current-threshold threshold
               ref-name-list data-name-list
               over-count-threshold current-over-count-threshold
               hand which-hand?
               current-over-flag nil
               current-over-count 0
               ref-angle-list (list 0.0 (* pi (/ 60 180.0)) (* pi (/ 90 180.0)) (* pi (/ 120 180.0))))
         (format t "~A current-threshold ~A~%" hand current-threshold)
         (format t "topic = ~A_hand_controller/joint_states~%" hand)
         (ros::subscribe (format nil "~A_hand_controller/joint_states" hand) sensor_msgs::JointState #'send self :call-back)
         (ros::advertise (format nil "~A_hand_controller/current_over_flag" hand) std_msgs::Bool 1)
         self)
  (:call-back(msg)
             (setq current-value (send self :sort-by-name (send msg :effort) (send msg :name) ref-name-list))
             (setq position-value (send self :sort-by-name (send msg :position) (send msg :name) ref-name-list)) ;;rad
             ;; (format t "current-value=~A~%" current-value)
             (send self :check-list current-value))
  (:check-list(lis)
              (dotimes (i (length current-value))
                (if (< (elt current-threshold i) (elt current-value i))
                    (progn
                      (format t "over current-threshold mortor: idx=~A, value=~A~%" i (elt current-value i))
                      (if (< over-count-threshold current-over-count)
                          (setq current-over-flag t))
                      (setq current-over-count (+ current-over-count 1))
                      (format t "current-over-count=~A~%" current-over-count)
                      (return-from nil i))))
              (if current-over-flag
                  (progn
                    (format t "[~A hand] stop motion~%" hand)
                    ;; (send (read-from-string (if (equal hand "left") (format nil "*lhand-ri*") (format nil "*rhand-ri*"))) :stop-motion)
                    (setq res (instance std_msgs::Bool :init))
                    (send res :data t)
                    (ros::publish (format nil "~A_hand_controller/current_over_flag" hand) res)
                    ;; (if (equal hand "left")
                    ;;     (send *lhand-ri* :stop-motion)
                    ;;   (send *rhand-ri* :stop-motion))
                    (format t "position-value=~A~%" position-value)
                    ;;index finger
                    (setq index-lock-angle (send self :nearest-angle (elt position-value 2) ref-angle-list))
                    ;;middle finger
                    (setq middle-lock-angle (send self :nearest-angle (elt position-value 4) ref-angle-list))
                    ;; (format t "lock-angles ~A~%"  (list index-lock-angle middle-lock-angle))
                    ;; (lock-finger (read-from-string (format nil ":~A" hand)) :lock-angles (list index-lock-angle middle-lock-angle) :send? send?)
                    (setq current-over-count 0)
                    (setq current-over-flag nil))))
  ;;sort order of data
  ;;   The topic names were listed in order from thumb to lock, so the order of the data is also appropriate.
  ;; Therefore, it is necessary to rearrange the data to be retrieved from the topic into the proper order for use.
  ;;(send *ins* :sort-by-name (list 30 10 20) (list "c" "a" "b") (list "a" "b" "c"))
  (:sort-by-name(data-list name-list ref-name-list)
             (setq sorted-idx-list (list 0)
                   sorted-value-list (list 0))
             (dotimes (i (length ref-name-list))
               (setq idx (- (length name-list) (length (member (elt ref-name-list i) name-list :test #'equal))))
               (list-insert idx 100 sorted-idx-list))
             ;; (format t "result=~A~%" sorted-idx-list)
             (dotimes (i (length (cdr sorted-idx-list)))
               (list-insert (elt data-list (elt (cdr sorted-idx-list) i)) 100  sorted-value-list))
             (cdr sorted-value-list))
  (:get-min(lis)
           (setq min-idx 0)
           (setq min-value (elt lis 0))
           (dotimes (i (length lis))
             (if (< (elt lis i) min-value)
                 (progn
                   (setq min-idx i)
                   (setq min-value (elt lis i)))))
           (format t "(list min-idx min-value)=~A~%" (list min-idx min-value))
           (list min-idx min-value))
  ;; Output the angle closest to the presetnt-angle among the angles in the angle-list
  (:nearest-angle(present-angle angle-list)
                 (let ((diff-list (list 1000)))
                   (dotimes (i (length angle-list))
                     (list-insert (abs (- (elt angle-list i) (abs present-angle))) 100 diff-list))
                   (format t "(cdr diff-list)=~A~%" (cdr diff-list))
                   (setq min-idx-value (send self :get-min (cdr diff-list)))
                   (elt angle-list (car min-idx-value)))))

(setq *ins-left* (instance auto-lock-one-hand :init "left" (list 10000 10000 100 10000 100 10000) (list "L_THUMB_JOINT0" "L_THUMB_JOINT1" "L_INDEX_JOINT0" "L_INDEX_JOINT1" "L_MIDDLE_JOINT0" "L_LOCK_JOINT0") 4))
(setq *ins-right* (instance auto-lock-one-hand :init "right" (list 10000 10000 100 10000 100 10000) (list "R_THUMB_JOINT0" "R_THUMB_JOINT1" "R_INDEX_JOINT0" "R_INDEX_JOINT1" "R_MIDDLE_JOINT0" "R_LOCK_JOINT0") 4))

(do-until-key
 (ros::spin-once)
)

