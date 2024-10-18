;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-prediction (err u102))
(define-constant err-market-closed (err u103))
(define-constant err-already-claimed (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-invalid-parameter (err u106))

;; Data vars
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var minimum-stake uint u1000000) ;; 1 STX
(define-data-var fee-percentage uint u2) ;; 2%
(define-data-var market-counter uint u0)

;; Maps
(define-map markets
  uint
  {
    start-price: uint,
    end-price: uint,
    total-up-stake: uint,
    total-down-stake: uint,
    start-block: uint,
    end-block: uint,
    resolved: bool
  }
)

(define-map user-predictions
  {market-id: uint, user: principal}
  {prediction: (string-ascii 4), stake: uint, claimed: bool}
)

(define-public (create-market (start-price uint) (start-block uint) (end-block uint))
  (let
    (
      (market-id (var-get market-counter))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> end-block start-block) err-invalid-parameter)
    (asserts! (> start-price u0) err-invalid-parameter)
    (map-set markets market-id
      {
        start-price: start-price,
        end-price: u0,
        total-up-stake: u0,
        total-down-stake: u0,
        start-block: start-block,
        end-block: end-block,
        resolved: false
      }
    )
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

(define-public (make-prediction (market-id uint) (prediction (string-ascii 4)) (stake uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (current-block block-height)
    )
    (asserts! (and (>= current-block (get start-block market)) (< current-block (get end-block market))) err-market-closed)
    (asserts! (or (is-eq prediction "up") (is-eq prediction "down")) err-invalid-prediction)
    (asserts! (>= stake (var-get minimum-stake)) err-invalid-prediction)
    (asserts! (<= stake (stx-get-balance tx-sender)) err-insufficient-balance)
    
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    
    (map-set user-predictions {market-id: market-id, user: tx-sender}
      {prediction: prediction, stake: stake, claimed: false}
    )
    
    (map-set markets market-id
      (merge market
        {
          total-up-stake: (if (is-eq prediction "up")
                            (+ (get total-up-stake market) stake)
                            (get total-up-stake market)),
          total-down-stake: (if (is-eq prediction "down")
                              (+ (get total-down-stake market) stake)
                              (get total-down-stake market))
        }
      )
    )
    (ok true)
  )
)

(define-public (resolve-market (market-id uint) (end-price uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (var-get oracle-address)) err-owner-only)
    (asserts! (>= block-height (get end-block market)) err-market-closed)
    (asserts! (not (get resolved market)) err-market-closed)
    (asserts! (> end-price u0) err-invalid-parameter)
    
    (map-set markets market-id
      (merge market
        {
          end-price: end-price,
          resolved: true
        }
      )
    )
    (ok true)
  )
)

(define-public (claim-winnings (market-id uint))
  (let
    (
      (market (unwrap! (map-get? markets market-id) err-not-found))
      (prediction (unwrap! (map-get? user-predictions {market-id: market-id, user: tx-sender}) err-not-found))
    )
    (asserts! (get resolved market) err-market-closed)
    (asserts! (not (get claimed prediction)) err-already-claimed)
    
    (let
      (
        (winning-prediction (if (> (get end-price market) (get start-price market)) "up" "down"))
        (total-stake (+ (get total-up-stake market) (get total-down-stake market)))
        (winning-stake (if (is-eq winning-prediction "up") (get total-up-stake market) (get total-down-stake market)))
      )
      (asserts! (is-eq (get prediction prediction) winning-prediction) err-invalid-prediction)
      
      (let
        (
          (winnings (/ (* (get stake prediction) total-stake) winning-stake))
          (fee (/ (* winnings (var-get fee-percentage)) u100))
          (payout (- winnings fee))
        )
        (try! (as-contract (stx-transfer? payout (as-contract tx-sender) tx-sender)))
        (try! (as-contract (stx-transfer? fee (as-contract tx-sender) contract-owner)))
        
        (map-set user-predictions {market-id: market-id, user: tx-sender}
          (merge prediction {claimed: true})
        )
        (ok payout)
      )
    )
  )
)

;; Getter functions

(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

(define-read-only (get-user-prediction (market-id uint) (user principal))
  (map-get? user-predictions {market-id: market-id, user: user})
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Admin functions

(define-public (set-oracle-address (new-address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    ;; Add validation for new-address if necessary
    (ok (var-set oracle-address new-address))
  )
)

(define-public (set-minimum-stake (new-minimum uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    ;; Ensure new-minimum is greater than zero
    (asserts! (> new-minimum u0) err-invalid-parameter)
    (ok (var-set minimum-stake new-minimum))
  )
)

(define-public (set-fee-percentage (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u100) err-invalid-parameter)
    (ok (var-set fee-percentage new-fee))
  )
)

(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount (stx-get-balance (as-contract tx-sender))) err-insufficient-balance)
    (try! (as-contract (stx-transfer? amount (as-contract tx-sender) contract-owner)))
    (ok amount)
  )
)