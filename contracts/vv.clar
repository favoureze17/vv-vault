;; VelvetVault - Premium Royalty Distribution Smart Contract
;; A sophisticated system for automated and fair royalty distribution

;; Define constants
(define-constant VAULT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_PERCENTAGE (err u101))
(define-constant ERR_NO_STAKEHOLDERS (err u102))
(define-constant ERR_INVALID_STAKEHOLDER (err u103))
(define-constant ERR_PAYMENT_FAILED (err u104))
(define-constant ERR_STAKEHOLDER_NOT_FOUND (err u105))
(define-constant ERR_DISTRIBUTION_FAILED (err u106))
(define-constant ERR_TOO_EARLY (err u107))
(define-constant ERR_INVALID_INTERVAL (err u108))
(define-constant ERR_INVALID_AMOUNT (err u109))
(define-constant ERR_TOO_MANY_STAKEHOLDERS (err u110))

;; Core data structures for stakeholder management
(define-map stakeholder-shares principal uint)     ;; Maps stakeholder to their percentage share
(define-map stakeholder-registry uint principal)   ;; Maps index to stakeholder address
(define-map stakeholder-lookup principal uint)     ;; Maps stakeholder to their index
(define-map vault-distributions uint uint)         ;; Tracks distributed amounts per block
(define-map stakeholder-earnings principal uint)   ;; Tracks lifetime earnings per stakeholder

;; State variables for vault management
(define-data-var total-stakeholders uint u0)           ;; Current number of stakeholders
(define-data-var payout-frequency uint u1440)          ;; Distribution interval in blocks (~1 day)
(define-data-var last-payout-block uint u0)            ;; Block height of last distribution
(define-data-var vault-status bool true)               ;; Vault active/inactive status

;; Core function to configure stakeholder royalty shares
;; Adds new stakeholders or updates existing ones
(define-public (configure-stakeholder (stakeholder principal) (share-percentage uint))
  (begin
    ;; Verify caller is vault owner
    (asserts! (is-eq tx-sender VAULT_OWNER) ERR_UNAUTHORIZED)
    ;; Validate percentage is within bounds
    (asserts! (<= share-percentage u100) ERR_INVALID_PERCENTAGE)
    ;; Ensure vault is active
    (asserts! (var-get vault-status) (err u111))
    
    ;; Add new stakeholder if they don't exist
    (if (is-none (map-get? stakeholder-shares stakeholder))
      (let ((current-index (var-get total-stakeholders)))
        (map-set stakeholder-registry current-index stakeholder)
        (map-set stakeholder-lookup stakeholder current-index)
        (var-set total-stakeholders (+ current-index u1)))
      true)
    
    ;; Set or update stakeholder's share percentage
    (ok (map-set stakeholder-shares stakeholder share-percentage))))

;; Distribute royalties to a specific stakeholder by index
;; Includes comprehensive validation and error handling
(define-public (execute-payout (stakeholder-index uint) (distribution-amount uint))
  (let ((total-stakeholder-count (var-get total-stakeholders)))
    ;; Validate stakeholder index
    (if (>= stakeholder-index total-stakeholder-count)
      (err ERR_INVALID_STAKEHOLDER)
      ;; Validate distribution amount
      (if (<= distribution-amount u0)
        (err ERR_INVALID_AMOUNT)
        ;; Process the payout
        (match (map-get? stakeholder-registry stakeholder-index)
          stakeholder-address 
            (let ((share-percent (default-to u0 (map-get? stakeholder-shares stakeholder-address)))
                  (payout-amount (/ (* distribution-amount share-percent) u100)))
              ;; Only process if stakeholder has a valid share
              (if (> share-percent u0)
                ;; Ensure payout amount is valid
                (if (> payout-amount u0)
                  (match (as-contract (stx-transfer? payout-amount tx-sender stakeholder-address))
                    success (begin
                      ;; Record distribution in current block
                      (map-set vault-distributions block-height
                        (+ (default-to u0 (map-get? vault-distributions block-height)) payout-amount))
                      ;; Update stakeholder's lifetime earnings
                      (map-set stakeholder-earnings stakeholder-address
                        (+ (default-to u0 (map-get? stakeholder-earnings stakeholder-address)) payout-amount))
                      (ok payout-amount))
                    error (err ERR_PAYMENT_FAILED))
                  (err ERR_INVALID_AMOUNT))
                ;; No payout for 0% stakeholders
                (ok u0)))
          ;; Stakeholder not found in registry
          (err ERR_STAKEHOLDER_NOT_FOUND))))))

;; Mass distribution to all stakeholders using manual unrolling
;; This approach avoids interdependent functions by handling common cases directly
(define-public (execute-mass-payout (total-distribution uint))
  (let ((stakeholder-count (var-get total-stakeholders)))
    ;; Verify stakeholders exist
    (if (is-eq stakeholder-count u0)
      (err ERR_NO_STAKEHOLDERS)
      ;; Handle different stakeholder counts manually to avoid interdependency
      (if (is-eq stakeholder-count u1)
        (execute-single-stakeholder-payout total-distribution)
        (if (is-eq stakeholder-count u2)
          (execute-two-stakeholder-payout total-distribution)
          (if (is-eq stakeholder-count u3)
            (execute-three-stakeholder-payout total-distribution)
            ;; For more than 3 stakeholders, use a simplified approach
            (execute-multiple-stakeholder-payout total-distribution stakeholder-count)))))))

;; Handle single stakeholder payout
(define-private (execute-single-stakeholder-payout (amount uint))
  (match (execute-payout u0 amount)
    distributed-amount (begin
      (map-set vault-distributions block-height distributed-amount)
      (ok distributed-amount))
    error (err ERR_DISTRIBUTION_FAILED)))

;; Handle two stakeholder payout
(define-private (execute-two-stakeholder-payout (amount uint))
  (match (execute-payout u0 amount)
    first-payment
      (match (execute-payout u1 amount)
        second-payment (begin
          (map-set vault-distributions block-height (+ first-payment second-payment))
          (ok (+ first-payment second-payment)))
        error (err ERR_DISTRIBUTION_FAILED))
    error (err ERR_DISTRIBUTION_FAILED)))

;; Handle three stakeholder payout
(define-private (execute-three-stakeholder-payout (amount uint))
  (match (execute-payout u0 amount)
    first-payment
      (match (execute-payout u1 amount)
        second-payment
          (match (execute-payout u2 amount)
            third-payment (begin
              (map-set vault-distributions block-height (+ (+ first-payment second-payment) third-payment))
              (ok (+ (+ first-payment second-payment) third-payment)))
            error (err ERR_DISTRIBUTION_FAILED))
        error (err ERR_DISTRIBUTION_FAILED))
    error (err ERR_DISTRIBUTION_FAILED)))

;; Handle multiple stakeholders (4 or more) with basic sequential processing
(define-private (execute-multiple-stakeholder-payout (amount uint) (count uint))
  (let ((total-paid u0))
    ;; For simplicity, this version processes up to 10 stakeholders
    ;; In production, you might want to implement pagination for larger numbers
    (if (<= count u10)
      (execute-up-to-ten-stakeholders amount)
      (err ERR_TOO_MANY_STAKEHOLDERS))))

;; Process up to 10 stakeholders manually
(define-private (execute-up-to-ten-stakeholders (amount uint))
  (let ((count (var-get total-stakeholders))
        (payment-0 (if (> count u0) (unwrap-panic (execute-payout u0 amount)) u0))
        (payment-1 (if (> count u1) (unwrap-panic (execute-payout u1 amount)) u0))
        (payment-2 (if (> count u2) (unwrap-panic (execute-payout u2 amount)) u0))
        (payment-3 (if (> count u3) (unwrap-panic (execute-payout u3 amount)) u0))
        (payment-4 (if (> count u4) (unwrap-panic (execute-payout u4 amount)) u0))
        (payment-5 (if (> count u5) (unwrap-panic (execute-payout u5 amount)) u0))
        (payment-6 (if (> count u6) (unwrap-panic (execute-payout u6 amount)) u0))
        (payment-7 (if (> count u7) (unwrap-panic (execute-payout u7 amount)) u0))
        (payment-8 (if (> count u8) (unwrap-panic (execute-payout u8 amount)) u0))
        (payment-9 (if (> count u9) (unwrap-panic (execute-payout u9 amount)) u0))
        (total-distributed (+ (+ (+ (+ payment-0 payment-1) (+ payment-2 payment-3)) 
                                (+ (+ payment-4 payment-5) (+ payment-6 payment-7))) 
                              (+ payment-8 payment-9))))
    (begin
      (map-set vault-distributions block-height total-distributed)
      (ok total-distributed))))

;; Automated recurring distribution system
;; Enforces time-based distribution intervals
(define-public (trigger-scheduled-payout (distribution-amount uint))
  (let ((current-block block-height)
        (previous-payout-block (var-get last-payout-block))
        (required-interval (var-get payout-frequency)))
    ;; Check if enough blocks have passed
    (if (>= (- current-block previous-payout-block) required-interval)
      (begin
        ;; Update last payout block and execute distribution
        (var-set last-payout-block current-block)
        (execute-mass-payout distribution-amount))
      (err ERR_TOO_EARLY))))

;; Configure the payout frequency interval
;; Only vault owner can modify timing settings
(define-public (update-payout-frequency (new-interval uint))
  (begin
    ;; Verify ownership
    (asserts! (is-eq tx-sender VAULT_OWNER) ERR_UNAUTHORIZED)
    ;; Validate interval
    (asserts! (> new-interval u0) ERR_INVALID_INTERVAL)
    ;; Update frequency setting
    (var-set payout-frequency new-interval)
    (ok new-interval)))

;; NEW FUNCTION: Emergency vault control system
;; Allows owner to pause/resume vault operations
(define-public (toggle-vault-status)
  (begin
    ;; Only vault owner can toggle status
    (asserts! (is-eq tx-sender VAULT_OWNER) ERR_UNAUTHORIZED)
    ;; Toggle vault status
    (let ((current-status (var-get vault-status)))
      (var-set vault-status (not current-status))
      (ok (not current-status)))))

;; === READ-ONLY QUERY FUNCTIONS ===

;; Get current payout frequency setting
(define-read-only (get-payout-frequency)
  (ok (var-get payout-frequency)))

;; Get block height of last distribution
(define-read-only (get-last-payout-block)
  (ok (var-get last-payout-block)))

;; Get stakeholder's share percentage
(define-read-only (get-stakeholder-share (stakeholder principal))
  (ok (default-to u0 (map-get? stakeholder-shares stakeholder))))

;; Get total distributed amount for current block
(define-read-only (get-current-block-distribution)
  (ok (default-to u0 (map-get? vault-distributions block-height))))

;; Get total number of stakeholders
(define-read-only (get-stakeholder-count)
  (ok (var-get total-stakeholders)))

;; Get stakeholder address by registry index
(define-read-only (get-stakeholder-by-index (index uint))
  (ok (map-get? stakeholder-registry index)))

;; NEW READ-ONLY: Get stakeholder's lifetime earnings
(define-read-only (get-stakeholder-earnings (stakeholder principal))
  (ok (default-to u0 (map-get? stakeholder-earnings stakeholder))))

;; NEW READ-ONLY: Get vault operational status
(define-read-only (get-vault-status)
  (ok (var-get vault-status)))

;; NEW READ-ONLY: Get comprehensive vault statistics
(define-read-only (get-vault-stats)
  (ok (tuple 
    (total-stakeholders (var-get total-stakeholders))
    (payout-frequency (var-get payout-frequency))
    (last-payout-block (var-get last-payout-block))
    (vault-active (var-get vault-status))
    (current-block-distribution (default-to u0 (map-get? vault-distributions block-height))))))