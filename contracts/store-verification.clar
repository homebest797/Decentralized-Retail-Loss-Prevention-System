;; Store Verification Contract
;; This contract validates legitimate retail locations

(define-data-var admin principal tx-sender)

;; Store data structure
(define-map stores
  { store-id: uint }
  {
    name: (string-utf8 100),
    address: (string-utf8 200),
    verified: bool,
    owner: principal
  }
)

;; Store count
(define-data-var store-count uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-STORE-NOT-FOUND u101)
(define-constant ERR-STORE-ALREADY-EXISTS u102)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new store
(define-public (register-store (name (string-utf8 100)) (address (string-utf8 200)))
  (let ((store-id (var-get store-count)))
    (asserts! (is-none (map-get? stores { store-id: store-id })) (err ERR-STORE-ALREADY-EXISTS))

    (map-set stores
      { store-id: store-id }
      {
        name: name,
        address: address,
        verified: false,
        owner: tx-sender
      }
    )

    (var-set store-count (+ store-id u1))
    (ok store-id)
  )
)

;; Verify a store (admin only)
(define-public (verify-store (store-id uint))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (match (map-get? stores { store-id: store-id })
      store-data (begin
        (map-set stores
          { store-id: store-id }
          (merge store-data { verified: true })
        )
        (ok true)
      )
      (err ERR-STORE-NOT-FOUND)
    )
  )
)

;; Get store information
(define-read-only (get-store (store-id uint))
  (map-get? stores { store-id: store-id })
)

;; Check if store is verified
(define-read-only (is-store-verified (store-id uint))
  (match (map-get? stores { store-id: store-id })
    store-data (ok (get verified store-data))
    (err ERR-STORE-NOT-FOUND)
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)
