(load "package://pr2eus/robot-interface.l")
(require :mhand_l "package://matsuura_hand/models/matsuura_hand_l.l")
(ros::load-ros-manifest "control_msgs")

(defclass matsuura_hand_l-interface
  :super robot-interface;;rtm-ros-robot-interface
  :slots ())
(defmethod matsuura_hand_l-interface
  (:init
    (&rest args &key ((:controller-timeout ct) 5))
    (prog1
      (send-super* :init :robot matsuura_hand_l-robot :controller-timeout ct :joint-states-topic "/left_hand_controller/joint_states" args) ;; :publish-joint-states-topic
      )
    )
  (:default-controller
    ()
    (list
      (list
        (cons :controller-action "left_hand_controller/follow_joint_trajectory_action")
        (cons :controller-state "left_hand_controller/state")
        (cons :action-type control_msgs::FollowJointTrajectoryAction)
        (cons :joint-names (mapcar #'(lambda (n) (if (symbolp n) (symbol-name n) n)) (send-all (send robot :joint-list) :name)))
        )
      )
    )
   ;; (:current-vector-simulation
  ;;  (av tm ctype)
  ;;  (let* ((prev-av (send robot :angle-vector)))
  ;;    (send-all (gethash ctype controller-table) :push-angle-vector-simulation av tm prev-av)))
  (:angle-vector-with-effort
   (av ef &optional (tm 1000) (ctype controller-type) (start-time 0) &key (scale 1))
   "Send joint angle to robot, this method returns immediately, so use :wait-interpolation to block until the motion stops.
- av : joint angle vector [deg]
- ef : current vector [deg]
- tm : (time to goal in [msec])
   if designated tm is faster than fastest speed, use fastest speed
   if not specified, it will use 1/scale of the fastest speed .
   if :fast is specified use fastest speed calculated from max speed
- start-time : time to start moving
- scale : if tm is not specified, it will use 1/scale of the fastest speed
"
   (format t "angle-vector: ~A, effort: ~A~%" av ef)
   (if (or (< (elt ef 0) 0) (< (elt ef 1) 0) (< (elt ef 2) 0) (< (elt ef 3) 0) (< (elt ef 4) 0) (< (elt ef 5) 0) (< 1 (elt ef 0)) (< 1 (elt ef 1)) (< 1 (elt ef 2)) (< 1 (elt ef 3)) (< 1 (elt ef 4)) (< 1 (elt ef 5)))
       (progn
	 (format t "!! effort: out of range [0.0, 1.0] !!~%")
	 (return-from :angle-vector-with-effort nil)))
   ;; for simulation mode
   ;; (when (send self :simulation-modep)
   ;;   (if ef (send self :current-vector-simulation ef tm ctype)))
   ;; (let ((trajpoint (list (instantiate float-vector (length ef));; positions
   (let ((trajpoint (list av ;; positions
                 (instantiate float-vector (length ef));; velocities
                 (/ tm 1000.0);; duration
                 (instantiate float-vector (length ef));; accelerations
                 ef));; current vector
         (joint-names (cdr (assoc :joint-names (car (send self ctype))))))
     ;;model
     ;; !!!     (send robot :angle-vector av)

     ;; (mapcar
       ;;  #'(lambda (action param)
       ;;      (send self :send-ros-controller
       ;;            action (cdr (assoc :joint-names param)) ;; action server and joint-names
       ;;            start-time  ;; start time
       ;;            trajpoints))
        ;; caction (send self ctype))))
  ;; (send self :send-ros-controller
  ;;       caction (cdr (assoc :joint-names (send self ctype))) ;; action server and joint-names
  ;;       start-time  ;; start time
  ;;       trajpoint)
  ;; av)
  ;; (:send-ros-controller
     ;;  (action joint-names starttime trajpoints)

   ;;simulation
   ;; (when (send self :simulation-modep)
     ;;   (return-from :send-ros-controller nil))
   (dolist (name joint-names)
     (unless (send robot :joint name)
       (warning-message 1 "[robot-interface.l] (send-ros-controller) could not find joint-name '~A' (~A)~%" name (send robot :joint name))
       (return-from :current-vector nil)))
   (let* ((caction (car (gethash ctype controller-table)))
          ;; (caction (cdr (assoc :action-type (car (send self ctype)))))
          (goal (send caction :make-goal-instance))
	  (goal-points nil)
	  (st (if (numberp start-time)
                  (ros::time+ (ros::time-now) (ros::time start-time))
                start-time))
	  (joints (mapcar #'(lambda (x)
                          (send robot (intern (string-upcase x) *keyword-package*)))
                      joint-names)))
     (send goal :header :seq 1)
     (send goal :header :stamp st)

     (send goal :goal :trajectory :joint_names joint-names)
     (send goal :goal :trajectory :header :stamp st)
     (let* ((all-positions (elt trajpoint 0))
            (all-velocities (elt trajpoint 1))
            (duration (elt trajpoint 2))
            (all-accelerations (elt trajpoint 3))
            (all-efforts (elt trajpoint 4))
            (positions (instantiate float-vector (length joint-names)))
            (velocities (instantiate float-vector (length joint-names)))
            (accelerations (instantiate float-vector (length joint-names)))
            (efforts (instantiate float-vector (length joint-names))))
       (dotimes (i (length joints))
         (let* ((joint (elt joints i))
                (id (position joint (send robot :joint-list)))
                p v a e)
           (setq p (elt all-positions id)
                 v (elt all-velocities id)
                 a (elt all-accelerations id)
                 e (elt all-efforts id))
           (cond
            ((derivedp joint rotational-joint)
             (setq p (deg2rad p))
             (setq v (deg2rad v))
             (setq a (deg2rad a))
             ;; (setq e (deg2rad e))
             )
            (t
             (setq p (* 0.001 p))
             (setq v (* 0.001 v))
             (setq a (* 0.001 a))
             ;; (setq e (* 0.001 e))
             ))
             (setf (elt positions i) p)
             (setf (elt velocities i) v)
             (setf (elt accelerations i) a)
             (setf (elt efforts i) e)))
         (push (instance trajectory_msgs::JointTrajectoryPoint
                         :init
                         :positions positions
                         ;; :velocities velocities
                         ;; :accelerations accelerations
                         :effort efforts
                         :time_from_start (ros::time duration))
               goal-points)
	   )
       (send self :spin-once)
       (send goal :goal :trajectory :points goal-points)
     (send caction :send-goal goal)
     )))

  (:finger-lock
   (&key (lock-angle #f(90)) (effort #f(1 1 1 1 1 0.1)) (send? nil))
   (format t "set :lock-angles like #f(90 90)~%")
   (if (not (memq (elt lock-angles 1) (list 0.0 60.0 90.0 120.0)))
      (progn
        (format t "please set lock-angle in 0 60 90 120 ~%")
        (return-from :finger-lock nil)))

   (when (boundp '*lhand-ri*)
     (format t "larm lock motion~%")
     (setq lock-motion '()
           lhand-ri-angle (send *lhand-ri* :state :angle-vector))
     ;;reset finger angle
     (replace lhand-ri-angle (float-vector (* -1 120)) :start1 2)
     (replace lhand-ri-angle (float-vector (* -1 120)) :start1 4)
     (replace lhand-ri-angle #f(0.0) :start1 5)
     (setq lock-motion (list-insert (copy-seq lhand-ri-angle) 3 lock-motion))
     ;; send index, middle joint angle (lock-angle+20)
     (replace lhand-ri-angle (float-vector (* -1 (if (equal (elt lock-angles 0) 0) 0 (- (elt lock-angles 0) 20)))) :start1 2)
     (replace lhand-ri-angle (float-vector (* -1 (if (equal (elt lock-angles 1) 0) 0 (- (elt lock-angles 1) 20)))) :start1 4)
     (replace lhand-ri-angle #f(0.0) :start1 5)
     (setq lock-motion (list-insert (copy-seq lhand-ri-angle) 3 lock-motion))
     ;;send lock-joint angle 14
     (replace lhand-ri-angle (if (equal lock-angles #f(0.0 0.0)) #f(0.0) #f(-14.0)) :start1 5)
     (setq lock-motion (list-insert (copy-seq lhand-ri-angle) 3 lock-motion))
     ;; send index, middle joint angle (lock-angle+30)
     (replace lhand-ri-angle (float-vector (* -1 (if (equal (elt lock-angles 0) 0) 0 (- (elt lock-angles 0) 30)))) :start1 2)
     (replace lhand-ri-angle (float-vector (* -1 (if (equal (elt lock-angles 1) 0) 0 (- (elt lock-angles 1) 30)))) :start1 4)
     (setq lock-motion (list-insert (copy-seq lhand-ri-angle) 3 lock-motion))

     (dotimes (i (length lock-motion))
       (send *lhand* :angle-vector (pop lock-motion))
       (if send?
           (progn
             (send *lhand-ri* :angle-vector-with-effort (send *lhand* :angle-vector) effort 500)
             (send *lhand-ri* :wait-interpolation)))
       (unix:usleep 2000))))
  )

(defun mhand_l-init (&rest args)
  (if (not (boundp '*ri*))
    (setq *ri* (instance* matsuura_hand_l-interface :init args)))
  (if (not (boundp '*mhand_l*))
    (setq *mhand_l* (instance matsuura_hand_l-robot :init)))
  )
