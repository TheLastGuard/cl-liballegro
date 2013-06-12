;;;; Higher Level Interface
(in-package #:cl-liballegro)

(defclass display-settings ()
  ((width :initarg :width :reader width)
   (height :initarg :height :reader height)
   (title :initarg :title :initform "" :reader title)
   (display-flags :initarg :display-flags :initform 0 :reader display-flags)
   (display-options :initarg :display-options :initform '() :reader display-options)))

(defclass system (display-settings)
  ((event-queue :accessor event-queue)
   (display :accessor display)
   (event :reader event :initform (cffi:foreign-alloc '(:union al:event)))
   (system-loop-running-p :accessor system-loop-running-p :initform t)
   (system-time :accessor system-time)
   (new-time :accessor new-time)
   (frame-time :accessor frame-time)
   (accumulator :accessor accumulator :initform 0.0)
   (logic-fps :accessor logic-fps :initarg :logic-fps :initform 30)))

;;; Generic Initializations
(defgeneric initialize-event-queue (sys))
(defgeneric initialize-display (sys))
(defgeneric initialize-mouse (sys))
(defgeneric initialize-keyboard (sys))
;;; Initialization Methods
(defmethod initialize-event-queue ((sys system))
  (setf (event-queue sys) (al:create-event-queue)))
(defmethod initialize-display ((sys system))
  (al:set-new-display-flags (display-flags sys))
  (loop for (option val importance) in (display-options sys) do
       (al:set-new-display-option option val importance))
  (setf (display sys) (al:create-display (width sys) (height sys)))
  (al:set-window-title (display sys) (title sys))
  (al:register-event-source (event-queue sys)
			    (al:get-display-event-source (display sys))))
(defmethod initialize-mouse ((sys system))
  (al:install-mouse)
  (al:register-event-source (event-queue sys) (al:get-mouse-event-source)))
(defmethod initialize-keyboard ((sys system))
  (al:install-keyboard)
  (al:register-event-source (event-queue sys) (al:get-keyboard-event-source)))

;;; Generic Handlers
(defgeneric joystick-axis-handler (sys))
(defgeneric joystick-button-down-handler (sys))
(defgeneric joystick-button-up-handler (sys))
(defgeneric joystick-configuration-handler (sys))
(defgeneric key-down-handler (sys))
(defgeneric key-char-handler (sys))
(defgeneric key-up-handler (sys))
(defgeneric mouse-axis-handler (sys))
(defgeneric mouse-button-down-handler (sys))
(defgeneric mouse-button-up-handler (sys))
(defgeneric mouse-enter-display-handler (sys))
(defgeneric mouse-leave-display-handler (sys))
(defgeneric mouse-warped-handler (sys))
(defgeneric timer-handler (sys))
(defgeneric display-expose-handler (sys))
(defgeneric display-resize-handler (sys))
(defgeneric display-close-handler (sys))
(defgeneric display-lost-handler (sys))
(defgeneric display-found-handler (sys))
(defgeneric display-switch-in-handler (sys))
(defgeneric display-switch-out-handler (sys))
(defgeneric display-switch-orientation-handler (sys))
;;; Handler Methods
(defmethod joystick-axis-handler ((sys system)))
(defmethod joystick-button-down-handler ((sys system)))
(defmethod joystick-button-up-handler ((sys system)))
(defmethod joystick-configuration-handler ((sys system)))
(defmethod key-down-handler ((sys system)))
(defmethod key-char-handler ((sys system)))
(defmethod key-up-handler ((sys system)))
(defmethod mouse-axis-handler ((sys system)))
(defmethod mouse-button-down-handler ((sys system)))
(defmethod mouse-button-up-handler ((sys system)))
(defmethod mouse-enter-display-handler ((sys system)))
(defmethod mouse-leave-display-handler ((sys system)))
(defmethod mouse-warped-handler ((sys system)))
(defmethod timer-handler ((sys system)))
(defmethod display-expose-handler ((sys system)))
(defmethod display-resize-handler ((sys system)))
(defmethod display-close-handler ((sys system))
  (setf (system-running-p sys) nil))
(defmethod display-lost-handler ((sys system)))
(defmethod display-found-handler ((sys system)))
(defmethod display-switch-in-handler ((sys system)))
(defmethod display-switch-out-handler ((sys system)))
(defmethod display-switch-orientation-handler ((sys system)))

(defgeneric event-handler (sys))
(defmethod event-handler ((sys system))
  (case (cffi:foreign-slot-value (event sys) '(:union al:event) 'al::type)
    (:joystick-axis (joystick-axis-handler sys))
    (:joystick-button-down (joystick-button-down-handler sys))
    (:joystick-button-up (joystick-button-up-handler sys))
    (:joystick-configuration (joystick-configuration-handler sys))
    (:key-down (key-down-handler sys))
    (:key-char (key-char-handler sys))
    (:key-up (key-up-handler sys))
    (:mouse-axis (mouse-axis-handler sys))
    (:mouse-button-down (mouse-button-down-handler sys))
    (:mouse-button-up (mouse-button-up-handler sys))
    (:mouse-enter-display (mouse-enter-display-handler sys))
    (:mouse-leave-display (mouse-leave-display-handler sys))
    (:mouse-warped (mouse-warped-handler sys))
    (:timer (timer-handler sys))
    (:display-expose (display-expose-handler sys))
    (:display-resize (display-resize-handler sys))
    (:display-close (display-close-handler sys))
    (:display-lost (display-lost-handler sys))
    (:display-found (display-found-handler sys))
    (:display-switch-in (display-switch-in-handler sys))
    (:display-switch-out (display-switch-out-handler sys))
    (:display-switch-orientation (display-switch-orientation-handler sys))))

(defgeneric process-event-queue (sys))
(defmethod process-event-queue ((sys system))
  (loop while (al:get-next-event (event-queue sys) (event sys)) do
       (event-handler sys)))



(defgeneric update (sys))
(defmethod update ((sys system)))
(defgeneric render (sys))
(defmethod render ((sys system)))

(defgeneric system-loop (sys))
(defmethod system-loop ((sys system))
  (with-slots (system-time new-time frame-time accumulator logic-fps) sys
    (setf new-time (get-time))
    (setf frame-time (- new-time system-time))
    (if (> frame-time (/ 1.0 logic-fps))
	(setf frame-time (/ 1.0 logic-fps)))
    (setf system-time new-time)
    (incf accumulator frame-time)
    (loop while (>= accumulator (/ 1.0 logic-fps)) do
	 (process-event-queue sys)
	 (update sys)
	 (decf accumulator (/ 1.0 logic-fps)))
    (render sys)))

(defun run-system (sys)
  (sb-ext:gc :full t)
  (al:init)
  (setf (system-time sys) (al:get-time))
  (al:init-image-addon)
  (al:init-font-addon)
  (al:init-ttf-addon)
  (initialize-event-queue sys)
  (initialize-display sys)
  (initialize-mouse sys)
  (initialize-keyboard sys)
  (loop while (system-loop-running-p sys) do
       (system-loop sys))
  (al:destroy-display (display sys))
  (al:destroy-event-queue (event-queue sys))
  (cffi:foreign-free (event sys)))



