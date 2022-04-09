#!/usr/bin/env roseus
;; (load "package://msl_hand_controller/euslisp/msl-hand-interface.l")
(ros::load-ros-manifest "msl_hand_controller")
(ros::roseus "current-over-count")

;; current-over-count: Total number of exceeds for all fingers
;;pub: "~A_hand_controller/current_over_flag": t or nil:
;;     "~A_hand_controller/current_over_array": (0 0 0 1 0 0):Sequentially returns a concatenated list of the current joint angle, current value, and a list with 1 for axes that exceeded the threshold value and 0 for all other axes.
;;output : current-over-array Axes exceeding the current threshold are set to 1, and all others are set to 0.
(defclass current-over-check-one-hand
  :super propertied-object
  :slots (hand position-value current-value current-threshold ref-angle-list current-over-flag ref-name-list current-over-count)
  )
(defmethod current-over-check-one-hand
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
         (ros::advertise (format nil "~A_hand_controller/current_over_array" hand) std_msgs::Float32MultiArray 1)
         self)
  (:call-back(msg)
             (setq current-value (send self :sort-by-name (send msg :effort) (send msg :name) ref-name-list))
             (setq position-value (send self :sort-by-name (send msg :position) (send msg :name) ref-name-list)) ;;rad
             ;; (format t "current-value=~A~%" current-value)
             (send self :check-list current-value))
  (:check-list(lis)
              (setq current-over-array (make-list (length current-value) :initial-element 0))
              (dotimes (i (length current-value))
                (if (< (elt current-threshold i) (elt current-value i))
                    (progn
                      (format t "over current-threshold mortor: idx=~A, value=~A~%" i (elt current-value i))
                      (if (< over-count-threshold current-over-count)
                          (setq current-over-flag t))
                      (setq current-over-count (+ current-over-count 1))
                      (format t "current-over-count=~A~%" current-over-count)
                      (setf (elt current-over-array i) 1)
                      (return-from nil i))))
              (setq result-array (instance std_msgs::Float32MultiArray :init))
              ;; (send (send result-array :layout) :dim 3)
              (dotimes (i 3)
                (setq dim (instance std_msgs::MultiArrayDimension))
                (send dim :size 6)
                (append  (send (send result-array :layout) :dim) dim))
              (send result-array :data (append position-value current-value current-over-array))
              (ros::publish (format nil "~A_hand_controller/current_over_array" hand) result-array)
              (if current-over-flag
                  (progn
                    ;; (format t "[~A hand] stop motion~%" hand)
                    ;; (send (read-from-string (if (equal hand "left") (format nil "*lhand-ri*") (format nil "*rhand-ri*"))) :stop-motion)
                    (setq res (instance std_msgs::Bool :init))
                    (send res :data t)
                    (ros::publish (format nil "~A_hand_controller/current_over_flag" hand) res)

                    ;; (if (equal hand "left")
                    ;;     (send *lhand-ri* :stop-motion)
                    ;;   (send *rhand-ri* :stop-motion))
                    (format t "position-value=~A~%" position-value)
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
             (cdr sorted-value-list)))

(setq *ins-left* (instance current-over-check-one-hand :init "left" (list 10000 10000 500 10000 500 10000) (list "L_THUMB_JOINT0" "L_THUMB_JOINT1" "L_INDEX_JOINT0" "L_INDEX_JOINT1" "L_MIDDLE_JOINT0" "L_LOCK_JOINT0") 4))
(setq *ins-right* (instance current-over-check-one-hand :init "right" (list 10000 10000 500 10000 500 10000) (list "R_THUMB_JOINT0" "R_THUMB_JOINT1" "R_INDEX_JOINT0" "R_INDEX_JOINT1" "R_MIDDLE_JOINT0" "R_LOCK_JOINT0") 4))

(do-until-key
 (ros::spin-once)
)
