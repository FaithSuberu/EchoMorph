;; Mirror NFT Behavioral Twin Token
;; -----------------------------------------------------
;; License: MIT
;;
;; Concept:
;; When a user mints an NFT, they receive two linked tokens:
;; 1. Original NFT  Tracks how often it changes hands.
;; 2. Mirror NFT    Evolves as the Original is transferred.
;;
;; Each transfer increments a counter.
;; After specific thresholds, the Mirrors metadata (URI)
;; is updated to a new version reflecting "evolution".
;; -----------------------------------------------------


;; -----------------------------------------------------
;; Constants and Errors
;; -----------------------------------------------------

(define-constant ERR-NOT-OWNER (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-NOT-A-PAIR (err u405))
(define-constant ERR-NOT-AUTHORIZED (err u406))

;; -----------------------------------------------------
;; Global Variables
;; -----------------------------------------------------

;; Token counter increments for each minted token
(define-data-var token-id uint u0)

;; Map: Original NFT Mirror NFT + transfer count
(define-map mirror-pairs
  {original: uint}
  {
    mirror: uint,
    transfers: uint
  }
)

;; Map: Token ID  Metadata (URI)
(define-map metadata
  {id: uint}
  {uri: (buff 256)}
)

;; Map: Token ID Owner
(define-map owners
  {id: uint}
  {holder: principal}
)

;; -----------------------------------------------------
;; Private Helper Functions
;; -----------------------------------------------------

(define-private (only-owner (id uint))
  (let ((info (map-get? owners {id: id})))
    (if (is-some info)
      (if (is-eq (get holder (unwrap! info ERR-NOT-FOUND)) tx-sender)
          (ok true)
          ERR-NOT-OWNER)
      ERR-NOT-FOUND)
  )
)

;; -----------------------------------------------------
;; Public: Mint Function Create Original + Mirror NFTs
;; -----------------------------------------------------

(define-public (mint-pair (orig-uri (buff 256)) (mirror-uri (buff 256)))
  (let (
        (id1 (+ (var-get token-id) u1))
        (id2 (+ (var-get token-id) u2))
      )
    (begin
      ;; Assign ownership
      (map-set owners {id: id1} {holder: tx-sender})
      (map-set owners {id: id2} {holder: tx-sender})

      ;; Store metadata
      (map-set metadata {id: id1} {uri: orig-uri})
      (map-set metadata {id: id2} {uri: mirror-uri})

      ;; Link the pair
      (map-set mirror-pairs {original: id1} {mirror: id2, transfers: u0})

      ;; Update counter
      (var-set token-id (+ id2 u1))

      (print {event: "minted-pair", original: id1, mirror: id2, owner: tx-sender})
      (ok {original: id1, mirror: id2})
    )
  )
)

;; -----------------------------------------------------
;; Public: Transfer Function (Original NFT)
;; -----------------------------------------------------

(define-public (transfer (id uint) (to principal))
  (begin
    ;; ensure caller is the owner (will return ERR-NOT-OWNER or ERR-NOT-FOUND on failure)
    (unwrap! (only-owner id) ERR-NOT-OWNER)

    ;; transfer ownership of the original token
    (map-set owners {id: id} {holder: to})

    ;; update the mirror's transfer counter / metadata (returns ok true/false)
    (unwrap! (update-mirror id) ERR-NOT-A-PAIR)

    (print {event: "transfer", id: id, to: to})
    (ok true)
  )
)

;; -----------------------------------------------------
;; Private: Mirror Update Logic
;; -----------------------------------------------------

(define-private (update-mirror (orig-id uint))
  (let ((pair (map-get? mirror-pairs {original: orig-id})))
    (if (is-some pair)
      (let (
            (old (unwrap! pair ERR-NOT-A-PAIR))
            (new-count (+ (get transfers old) u1))
            (mirror-id (get mirror old))
          )
        (begin
          ;; Increment transfer counter
          (map-set mirror-pairs {original: orig-id}
            {mirror: mirror-id, transfers: new-count})

          ;; Evolve mirror based on thresholds
          

          (print {event: "mirror-update", mirror: mirror-id, transfers: new-count})
          (ok true)
        )
      )
      (ok false)
    )
  )
)

;; -----------------------------------------------------
;; Read-Only Queries
;; -----------------------------------------------------

(define-read-only (get-owner (id uint))
  (let ((info (map-get? owners {id: id})))
    (if (is-some info)
      (ok (get holder (unwrap! info ERR-NOT-FOUND)))
      ERR-NOT-FOUND)
  )
)

(define-read-only (get-metadata (id uint))
  (let ((m (map-get? metadata {id: id})))
    (if (is-some m)
      (ok (get uri (unwrap! m ERR-NOT-FOUND)))
      ERR-NOT-FOUND)
  )
)

(define-read-only (get-pair-info (id uint))
  (map-get? mirror-pairs {original: id})
)

(define-read-only (get-total-supply)
  (ok (var-get token-id))
)
