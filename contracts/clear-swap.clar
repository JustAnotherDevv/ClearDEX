
;; clear-swap
;; author: NevvDevv
;; Token swap orderbook-based DEX on Stacks network

;; constants
;;
(define-constant contract-owner tx-sender)
(define-constant exchange-fee u100) 

;; error codes
(define-constant err-owner-only (err u200))
(define-constant err-not-token-owner (err u201))
(define-constant err-zero-stx (err u202))
(define-constant err-zero-tokens (err u203))
(define-constant err-zero-price (err u204))
(define-constant err-order-not-found (err u205))
(define-constant err-wrong-amount (err u206))
(define-constant err-user (err u207))

;; data maps and vars
;;

;; Buy orders for a given asset
(define-map buy-orders 
  uint 
  {
    user: principal, 
    amount: uint, 
    price: uint, 
    active: bool 
  }
)

;; Sell orders for a given asset
(define-map sell-orders 
  uint 
  {
    user: principal, 
    amount: uint, 
    price: uint, 
    active: bool 
  }
)

(define-data-var amount-of-buy-orders uint u0)
(define-data-var amount-of-sell-orders uint u0)
(define-data-var buy-orderbook-liquidity uint u0)
(define-data-var sell-orderbook-liquidity uint u0)

(define-data-var buy-orderbook-depth uint u0)
(define-data-var sell-orderbook-depth uint u0)


;; private functions
;;

;; @notice Checks if tx-sender is valid owner of given buy order
;; @param id - Index of the order to check
;; @returns Bool true if tx-sender is the owner
(define-private (is-buy-order-owner (id uint)) 
  (let
    (
      (owner (unwrap! (get user (map-get? buy-orders  id)) err-order-not-found))
    )
  (ok (is-eq owner tx-sender))
  )
)

;; @notice Checks if tx-sender is valid owner of given sell order
;; @param id - Index of the order to check
;; @returns Bool true if tx-sender is the owner
(define-private (is-sell-order-owner (id uint)) 
  (let
    (
      (owner (unwrap! (get user (map-get? sell-orders  id)) err-order-not-found))
    )
  (ok (is-eq owner tx-sender))
  )
)

;; public functions
;;

;; @notice Get the buy order details by id
;; @param id - Index of the order to check
;; @returns Tuple {buyer: principal, amount: uint, payment-currency: (string-ascii 3), price: uint, is-active: bool}
(define-read-only (get-buy-order-by-id (id uint))
(let
    (
      (buyer (unwrap! (get user (map-get? buy-orders id)) err-order-not-found))
      (amount (unwrap! (get amount (map-get? buy-orders id)) err-order-not-found))
      (price (unwrap! (get price (map-get? buy-orders id)) err-order-not-found))
      (active (unwrap! (get active (map-get? buy-orders id)) err-order-not-found))
    )
     (ok {buyer: buyer, amount: amount, payment-currency: "STX", price: price, is-active: active})
)
)

;; @notice Get the sell order details by id
;; @param id - Index of the order to check
;; @returns Tuple {seller: principal, amount: uint, payment-currency: (string-ascii 3), price: uint, is-active: bool}
(define-read-only (get-sell-order-by-id (id uint))
(let
    (
      (seller (unwrap! (get user (map-get? sell-orders id)) err-order-not-found))
      (amount (unwrap! (get amount (map-get? sell-orders id)) err-order-not-found))
      (price (unwrap! (get price (map-get? sell-orders id)) err-order-not-found))
      (active (unwrap! (get active (map-get? sell-orders id)) err-order-not-found))
    )
     (ok {seller: seller, amount: amount, payment-currency: "STX", price: price, is-active: active})
)
)

;; @notice Creates new buy order for tokens
;; @param amount - amount of tokens that user wants to buy
;; @param price - price in STX user is willing to pay for these tokens
;; @returns Bool true if new order was created successfully
(define-public (new-buy-order (amount uint) (price uint))
(begin
    (asserts! (> amount u0) err-zero-stx)
    (asserts! (> price u0) err-zero-price)
    (map-set buy-orders  (var-get amount-of-buy-orders) {user: tx-sender, amount: amount, price: price, active: true})
    (var-set amount-of-buy-orders (+ (var-get amount-of-buy-orders) u1))
    (var-set buy-orderbook-liquidity (+ (var-get amount-of-buy-orders) price))
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
    ;; (try! (fill-buy-order amount price))
    (ok true)
)
)

;; @notice Creates new sell order for tokens
;; @param amount - amount of tokens that user wants to sell
;; @param price - price in STX user wants in return
;; @returns Bool true if new order was created successfully
(define-public (new-sell-order (amount uint) (price uint))
(begin
    (asserts! (> amount u0) err-zero-stx)
    (asserts! (> price u0) err-zero-price)
    (map-set sell-orders (var-get amount-of-buy-orders) {user: tx-sender, amount: amount, price: price, active: true})
    (var-set amount-of-sell-orders (+ (var-get amount-of-sell-orders) u1))
    (var-set sell-orderbook-liquidity (+ (var-get amount-of-buy-orders) amount))
    (try! (contract-call? .clear-token transfer amount tx-sender (as-contract tx-sender) none))
    (ok true)
)
)

;; @notice Cancels buy order and returns funds to user
;; @param id - Index of the order to be removed
;; @returns Bool true if the order was cancelled
(define-public (cancel-buy-order (id uint))
(let
    (
      (price (unwrap! (get price (map-get? buy-orders id)) err-order-not-found))
    )
    (asserts! (> (var-get amount-of-buy-orders) id) err-order-not-found)
    (asserts! (try! (is-buy-order-owner id)) err-user)
    (try! (stx-transfer? price (as-contract tx-sender) tx-sender ))
    (map-set buy-orders id (merge (unwrap-panic (map-get? buy-orders id)) {amount: u0, price: u0, active: false}))
    (ok true)
)
)

;; @notice Cancels sell order and returns funds to user
;; @param id - Index of the order to be removed
;; @returns Bool true if the order was cancelled
(define-public (cancel-sell-order (id uint))
(let
    (
      (amount (unwrap! (get amount (map-get? sell-orders id)) err-order-not-found))
    )
    (asserts! (> (var-get amount-of-sell-orders) id) err-order-not-found)
    (asserts! (try! (is-sell-order-owner id)) err-user)
    (try! (contract-call? .clear-token transfer amount (as-contract tx-sender) tx-sender none))
    (map-set buy-orders id (merge (unwrap-panic (map-get? buy-orders id)) {amount: u0, price: u0, active: false}))
    (ok true)
)
)

;; @notice Fills selected buy order
;; @param id - Index of the order that should be filled
;; @returns Bool true if the order was filled successfully
(define-public (fill-buy-order (id uint))
(let
    (
      (buyer (unwrap! (get user (map-get? buy-orders id)) err-order-not-found))
      (amount (unwrap! (get amount (map-get? buy-orders id)) err-order-not-found))
      (price (unwrap! (get price (map-get? buy-orders id)) err-order-not-found))
      (stx-fee (/ (* price exchange-fee) u10000))
      (token-fee (/ (* amount exchange-fee) u10000))
    )
    (asserts! (> (var-get amount-of-buy-orders) id) err-order-not-found)
    ;; (asserts! (is-eq amount sender-amount ) err-wrong-amount)
    (try! (stx-transfer? (- price stx-fee) (as-contract tx-sender) tx-sender ))
    (try! (contract-call? .clear-token transfer (- amount token-fee) (as-contract tx-sender) buyer none))
    (map-set buy-orders id (merge (unwrap-panic (map-get? buy-orders id)) {amount: u0, price: u0, active: false}))
    (ok true)
)
)

;; @notice Fills selected sell order
;; @param id - Index of the order that should be filled
;; @returns Bool true if the order was filled successfully
(define-public (fill-sell-order (id uint))
(let
    (
      (seller (unwrap! (get user (map-get? buy-orders id)) err-order-not-found))
      (amount (unwrap! (get amount (map-get? buy-orders id)) err-order-not-found))
      (price (unwrap! (get price (map-get? buy-orders id)) err-order-not-found))
      (stx-fee (/ (* price exchange-fee) u10000))
      (token-fee (/ (* amount exchange-fee) u10000))
    )
    (asserts! (> (var-get amount-of-buy-orders) id) err-order-not-found)
    ;; (asserts! (is-eq amount sender-amount ) err-wrong-amount)
    (try! (stx-transfer? (- price stx-fee)  (as-contract tx-sender) seller ))
    (try! (contract-call? .clear-token transfer (- amount token-fee) (as-contract tx-sender) tx-sender none))
    (map-set sell-orders id (merge (unwrap-panic (map-get? buy-orders id)) {amount: u0, price: u0, active: false}))
    (ok true)
)
)

;; (define-public (buy-market-price (amount uint) (price uint))
;; (begin
;;     (asserts! (> amount u0) err-zero-stx)
;;     (asserts! (> price u0) err-zero-price)

;;     (ok true)
;; )
;; )