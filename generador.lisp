; Stat distributions
(ql:quickload :distributions)
(ql:quickload :array-operations)

; Normal distribution parameters
(defparameter *mu* 6)
(defparameter *sigma* 2)

(defparameter *lowest-demand* 40) ; L/min
(defparameter *highest-demand* 100) ; L/min

(defparameter *lowest-supply* 300) ; L/min
(defparameter *highest-supply* 1500) ; L/min

; Distribuciones a utilizar, se usa una normal para los costos y una uniforme para la demanda
(setf *random-state* (make-random-state t))
(defparameter *cost-distribution* (distributions:r-normal *mu* (* *sigma* *sigma*))) ; mu sigma^2
(defparameter *demand-distribution* (distributions:r-uniform *lowest-demand* *highest-demand*))
(defparameter *supply-distribution* (distributions:r-uniform *lowest-supply* *highest-supply*))

(defun generate-costs (from to)
  (aops:generate (lambda () (distributions:draw *cost-distribution*)) (list from to)))

(defclass pipe ()
  ((diameter
    :initarg :diameter
    :initform (error "Must supply a diameter")
    :accessor diameter
    :documentation "Diameter of the pipe in mm")
   (max-flow
    :initarg :max-flow
    :initform (error "Must supply max flow")
    :accessor max-flow
    :documentation "Max flow of the pipe in l/min")
   (installation-cost
    :initarg :installation-cost
    :initform (error "Must supply a list of costs")
    :accessor installation-cost
    :documentation "Supply cost of each producer")))

(defclass node ()
  ((supply
    :initarg :supply
    :initform (distributions:draw *demand-distribution*)
    :accessor supply
    :documentation "Supply of the node, by default draw from U(40, 100)")))

(defclass source ()
  ((max-supply
    :initarg :max-supply
    :initform (distributions:draw *supply-distribution*)
    :accessor max-supply)))

(defclass problem ()
  ((sources
    :initarg :sources
    :initform (error "Must supply quantity of sources")
    :accessor sources
    :documentation "Quantity of sources")
   (tanks
    :initarg :tanks
    :initform (error "Must supply quantity of tanks")
    :accessor tanks
    :documentation "Quantity of tanks")
   (trans-nodes
    :initarg :trans-nodes
    :initform (error "Must supply a list of trans-nodes")
    :accessor trans-nodes
    :documentation "List of trans nodes")
   (final-nodes
    :initarg :final-nodes
    :initform (error "Must supply a list of final-nodes")
    :accessor final-nodes
    :documentation "List of final nodes")
   (allowed-pipes
    :initarg :allowed-pipes
    :initform (error "Must supply a list of allowed pipes")
    :accessor allowed-pipes
    :documentation "List of allowed pipes")
   (cost-matrix-source-tanks
    :initarg :cost-matrix-source-tanks
    :accessor cost-matrix-source-tanks
    :documentation "Cost matrix from source to tanks")
   (cost-matrix-tanks-trans
    :initarg :cost-matrix-tanks-trans
    :accessor cost-matrix-tanks-trans
    :documentation "Cost matrix from tanks to trans nodes")
   (cost-matrix-trans-final
    :initarg :cost-matrix-trans-final
    :accessor cost-matrix-trans-final
    :documentation "Cost matrix from trans nodes to final nodes")))

(defmethod initialize-instance :after ((obj problem) &rest _)
  (with-slots (sources tanks trans-nodes final-nodes
               cost-matrix-source-tanks cost-matrix-tanks-trans cost-matrix-trans-final) obj
      (declare (ignore _))
      (setf cost-matrix-source-tanks (generate-costs (length sources) tanks))
      (setf cost-matrix-tanks-trans (generate-costs tanks (length trans-nodes)))
      (setf cost-matrix-trans-final (generate-costs (length trans-nodes) (length final-nodes)))))

(defmethod print-object ((object problem) stream)
  (print-unreadable-object (object stream :type t)
    (with-slots (sources tanks trans-nodes final-nodes) object
      (format stream "Sources: ~d~%Tanks: ~d~%Trans nodes: ~d~%Final nodes: ~d~%" (length sources) tanks (length trans-nodes) (length final-nodes)))))


(defparameter *available-pipes*
  (vector (make-instance 'pipe :diameter 50  :max-flow 353  :installation-cost (list :a 16 :b 45 :c 90))    ; D1
          (make-instance 'pipe :diameter 75  :max-flow 795  :installation-cost (list :a 20 :b 50 :c 120))   ; D2
          (make-instance 'pipe :diameter 100 :max-flow 1414 :installation-cost (list :a 24 :b 62 :c 145))   ; D3
          (make-instance 'pipe :diameter 120 :max-flow 2036 :installation-cost (list :a 27 :b 68 :c 170))   ; D4
          (make-instance 'pipe :diameter 150 :max-flow 3181 :installation-cost (list :a 32 :b 78 :c 210)))) ; D5

(defparameter *allowed-pipes*
  (vector (aref *available-pipes* 1)   ;D2
          (aref *available-pipes* 2)   ;D3
          (aref *available-pipes* 4))) ;D5

(defun random-values (list-of-lists)
  (let* ((keys '(:a :b))
        (random-key (nth (random (length keys)) keys)))
    (aops:each #'(lambda (sublist) (nth (1+ (position random-key sublist)) sublist)) list-of-lists)))

(defun write-matrix (matrix stream from to nombre)
  (let* ((rows (array-dimension matrix 0))
         (cols (array-dimension matrix 1)))
    ;; header + open bracket
    (format stream
            "array[~A, ~A] of float: ~A = array2d(~A, ~A,~%  ["
            from to nombre from to)

    ;; walk each row
    (loop for i below rows do
      ;; for rows > 0, indent on a new line
      (unless (= i 0)
        (format stream "~%   "))
      ;; walk each column in row i
      (loop for j below cols do
        (format stream "~,5f" (aref matrix i j))
        (cond
          ;; last element of last row? close up and semicolon.
          ((and (= i (- rows 1))
                (= j (- cols 1)))
           (format stream "]);"))
          ;; end of any other row? comma only
          ((= j (- cols 1))
           (format stream ","))
          ;; middle of a row? comma
          (t
           (format stream ",")))))
    ;; final newline
    (format stream "~%~%")))


(defun write-sets (problem stream)
    (format stream "set of int: SOURCES     = 1..~d;~%" (length (sources problem)))
    (format stream "set of int: TANKS       = 1..~d;~%" (tanks problem))
    (format stream "set of int: TRANS_NODES = 1..~d;~%" (length (trans-nodes problem)))
    (format stream "set of int: FINAL_NODES = 1..~d;~%" (length (final-nodes problem)))
    (format stream "set of int: PIPE_TYPE   = 1..~d;~%~%" (length (allowed-pipes problem))))

; Esto se mala praxis, la eleccion de precios deberia ser parte de la creacion del problema, es decir si llamamos a write-pipes con el mismo problema no deberia cambiar el output, pero w/e
(defun write-pipes (problem stream)
  (let ((prices (random-values (aops:each #'(lambda (pipe) (installation-cost pipe)) (allowed-pipes problem)))))
      (format stream "array [PIPE_TYPE] of int: price_of_pipe = [~{~d~^, ~}];~%" (coerce prices 'list))
      (format stream "array [PIPE_TYPE] of int: capacity      = [~{~d~^, ~}];~%~%" (coerce (aops:each #'(lambda (pipe) (max-flow pipe)) (allowed-pipes problem)) 'list))))

(defun write-demands (problem stream)
    (format stream "array[FINAL_NODES] of float: demand_final = [~{~,5f~^, ~}];~%" (coerce (aops:each #'(lambda (node) (supply node)) (final-nodes problem)) 'list))
    (format stream "array[TRANS_NODES] of float: demand_trans = [~{~,5f~^, ~}];~%~%" (coerce (aops:each #'(lambda (node) (supply node)) (trans-nodes problem)) 'list)))

(defun write-supply (problem stream)
    (format stream "array[SOURCES] of float: supply = [~{~,5f~^, ~}];~%" (coerce (aops:each #'(lambda (node) (max-supply node)) (sources problem)) 'list)))

(defun write-costs (problem stream)
    (write-matrix (cost-matrix-source-tanks problem) stream "SOURCES" "TANKS" "costs_sources_tanks")
    (write-matrix (cost-matrix-tanks-trans problem) stream "TANKS" "TRANS_NODES" "costs_tanks_trans")
    (write-matrix (cost-matrix-trans-final problem) stream "TRANS_NODES" "FINAL_NODES" "costs_trans_final"))

(defun inter-gen-instance (source-number tank-number C1-number C2-number filename)
  (let ((problem (make-instance 'problem
                 :sources (aops:generate (lambda () (make-instance 'source)) source-number)
                 :tanks tank-number
                 :trans-nodes (aops:generate (lambda () (make-instance 'node)) C1-number)
                 :final-nodes (aops:generate (lambda () (make-instance 'node)) C2-number)
                 :allowed-pipes *allowed-pipes*)))
    (with-open-file (stream filename :direction :output :if-does-not-exist :create :if-exists :overwrite)
      (write-sets problem stream)
      (write-pipes problem stream)
      (write-supply problem stream)
      (write-demands problem stream)
      (write-costs problem stream))))

(defun satisfable? (problem))

(defmacro definstance (name source-lower source-higher tank-lower tank-higher c1-lower c1-higher c2-lower c2-higher filename)
  `(defun ,name ()
     (let ((source-number (distributions:draw-uniform ,source-lower ,(+ 1 source-higher)))
           (tank-number (distributions:draw-uniform ,tank-lower ,(+ 1 tank-higher)))
           (c1-number (distributions:draw-uniform ,c1-lower ,(+ 1 c1-higher)))
           (c2-number (distributions:draw-uniform ,c2-lower ,(+ 1 c2-higher))))
       (inter-gen-instance source-number tank-number c1-number c2-number ,filename))))

(definstance gen-ultra-small-instance 1 1 2 3 4 5 2 2 "ultra.mzn")
(definstance gen-small-instance 1 2 5 10 5 10 10 20 "small.mzn")
(definstance gen-medium-instance 3 4 10 20 10 20 20 50 "medium.mzn")
(definstance gen-big-instance 5 7 20 50 25 50 50 100 "big.mzn")

(defun gen-instance (size)
  (ecase size
      (ultra    (gen-ultra-small-instance))
      (small    (gen-small-instance))
      (medium   (gen-medium-instance))
      (big      (gen-big-instance))))
